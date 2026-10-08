use std::path::Path;
use std::sync::atomic::AtomicUsize;
use std::sync::Arc;
use std::time::Duration;

use dashmap::DashMap;
use flutter_rust_bridge::frb;
use lazy_static::lazy_static;

use surrealdb_core::dbs::Session;
use surrealdb_core::kvs::{Datastore, QueryRequest, QuerySource};
use surrealdb_core::rpc::RpcProtocol;
use surrealdb_core::rpc::types_error_from_anyhow;
use surrealdb_datastore::Transaction;
use surrealdb_kvs::TransactionType;
use surrealdb_rpc::args::extract_args;
use surrealdb_rpc::capabilities::ExperimentalTarget;
use surrealdb_rpc::{DbResult, Method};
use surrealdb_sql::{
    Ast, Data, Expr, Function, FunctionCall, Literal, Model, Output, RelateStatement, TableName,
    UpdateStatement,
};
use surrealdb_types::{
    Array, HashMap, NotAllowedError, Notification, RecordIdKey, ValidationError, Value,
};
use tokio::sync::RwLock;
use uuid::Uuid;

use crate::api::engine::is_transaction_conflict;
use crate::api::options::Options;

lazy_static! {
    /// Process-wide registry of connections opened with a share tag. The Rust
    /// library is loaded once per process and its statics are shared by every
    /// Dart isolate, so a connect with a known tag attaches to the existing
    /// connection instead of opening the database file again, which would
    /// fail on the file lock held by that connection.
    pub(crate) static ref SHARED_CONNECTIONS: DashMap<String, Arc<SurrealFlutterConnection>> =
        DashMap::new();

    /// Serializes tagged connects so two concurrent connects with the same tag
    /// cannot both miss the registry lookup and both try to build a datastore.
    pub(crate) static ref SHARED_CONNECT_LOCK: tokio::sync::Mutex<()> = tokio::sync::Mutex::new(());
}

/// A live query created by a session. The namespace and database names are
/// snapshotted when the query is created so it can be killed later without
/// re-locking the session, which could deadlock against session mutations
/// already holding the lock (e.g. `invalidate` triggers cleanup while holding
/// a write lock).
#[derive(Clone)]
pub(crate) struct TrackedLiveQuery {
    pub session: Uuid,
    pub ns: Option<String>,
    pub db: Option<String>,
}

/// Fans live query notifications out to one channel per subscriber.
///
/// The datastore notification receiver (`async_channel`) is a competing
/// consumer: every message is handed to exactly one receiver clone, so with
/// more than one engine attached to a connection each engine must get its own
/// channel fed by a single drainer task.
pub(crate) struct NotificationHub {
    subscribers: std::sync::Mutex<Vec<channel::Sender<Notification>>>,
}

impl NotificationHub {
    pub(crate) fn new() -> Self {
        Self {
            subscribers: std::sync::Mutex::new(Vec::new()),
        }
    }

    pub(crate) fn subscribe(&self) -> channel::Receiver<Notification> {
        let (tx, rx) = channel::unbounded();
        self.subscribers.lock().unwrap().push(tx);
        rx
    }

    /// Forwards one notification to every subscriber, dropping subscribers
    /// whose receiving side has gone away.
    pub(crate) fn broadcast(&self, notification: Notification) {
        let mut subscribers = self.subscribers.lock().unwrap();
        subscribers.retain(|tx| tx.try_send(notification.clone()).is_ok());
    }
}

#[frb(ignore)]
pub(crate) struct SurrealFlutterConnection {
    pub kvs: Arc<Datastore>,
    pub sessions: HashMap<Uuid, Arc<RwLock<Session>>>,
    /// Fans datastore notifications out to the engines attached here.
    pub notifications: Arc<NotificationHub>,
    /// Live queries created through this connection, keyed by live query id.
    pub live_queries: DashMap<Uuid, TrackedLiveQuery>,
    /// Client-managed transactions opened through `begin`, keyed by
    /// transaction id. Statements join one by naming its id on the call.
    pub txns: DashMap<Uuid, Arc<Transaction>>,
    /// The session that opened each transaction, so a detached, reset or
    /// closed session cannot leak a write transaction.
    pub txn_sessions: DashMap<Uuid, Uuid>,
    /// Canonical form of the endpoint this connection was opened with; used
    /// to reject share-tag attaches that name a different endpoint.
    pub endpoint: String,
    /// The options this connection was created with. Attaches to a shared
    /// connection may only repeat these options verbatim (or pass none).
    pub opts: Option<Options>,
    /// How many engine handles are currently attached. Only maintained for
    /// connections in the registry; when this reaches zero the connection is
    /// deregistered and, with its datastore and file lock, dropped.
    pub leases: AtomicUsize,
}

impl SurrealFlutterConnection {
    /// Kills the given live queries by running a plain KILL statement on the
    /// datastore. This deliberately bypasses the RPC layer: `cleanup_lqs` can
    /// be invoked while the session is write-locked, and re-entering the RPC
    /// path would deadlock trying to read that same session.
    async fn kill_live_queries(&self, queries: Vec<(Uuid, TrackedLiveQuery)>) {
        for (lqid, tracked) in queries {
            let mut session = Session::default().with_rt(true);
            if let Some(ns) = &tracked.ns {
                session = session.with_ns(ns);
            }
            if let Some(db) = &tracked.db {
                session = session.with_db(db);
            }
            // A Uuid always renders in its hyphenated hexadecimal form, so
            // this text query cannot be injected with SurrealQL.
            let kill = format!("KILL u'{lqid}'");
            // A KILL that lost a transaction-conflict race is retried: the
            // caller's session teardown only completes correctly when the
            // kill actually lands, so a conflict must not silently swallow it.
            let mut attempt = 0u32;
            loop {
                match self.kvs.execute(&kill, &session, None).await {
                    Err(err) if attempt < 3 && is_transaction_conflict(&err) => {
                        attempt += 1;
                        tokio::time::sleep(Duration::from_millis(10 * attempt as u64)).await;
                    }
                    _ => break,
                }
            }
        }
    }
}

impl RpcProtocol for SurrealFlutterConnection {
    fn kvs(&self) -> &Datastore {
        &self.kvs
    }

    fn kvs_arc(&self) -> Arc<Datastore> {
        Arc::clone(&self.kvs)
    }

    fn version_data(&self) -> DbResult {
        DbResult::Other(Value::String(
            format!("surrealdb-{}", env!("SURREALDB_VERSION")).into(),
        ))
    }

    // ------------------------------
    // Sessions
    // ------------------------------

    /// The current session for this RPC context
    fn session_map(&self) -> &HashMap<Uuid, Arc<RwLock<Session>>> {
        &self.sessions
    }

    // ------------------------------
    // Realtime
    // ------------------------------

    const LQ_SUPPORT: bool = true;

    /// Tracks live queries created by a session so they can be killed when
    /// the session is closed or invalidated.
    async fn handle_live(
        &self,
        lqid: &Uuid,
        session_id: Uuid,
        namespace: Option<String>,
        database: Option<String>,
    ) {
        self.live_queries.insert(
            *lqid,
            TrackedLiveQuery {
                session: session_id,
                ns: namespace,
                db: database,
            },
        );
    }

    /// Kills all live queries belonging to [session_id].
    async fn cleanup_lqs(&self, session_id: &Uuid) {
        let queries = self
            .live_queries
            .iter()
            .filter(|entry| entry.value().session == *session_id)
            .map(|entry| (*entry.key(), entry.value().clone()))
            .collect::<Vec<_>>();
        for (lqid, _) in &queries {
            self.live_queries.remove(lqid);
        }
        self.kill_live_queries(queries).await;
    }

    /// Kills every live query created through this connection.
    async fn cleanup_all_lqs(&self) {
        let queries = self
            .live_queries
            .iter()
            .map(|entry| (*entry.key(), entry.value().clone()))
            .collect::<Vec<_>>();
        self.live_queries.clear();
        self.kill_live_queries(queries).await;
    }

    // ------------------------------
    // Transactions
    // ------------------------------

    async fn get_tx(&self, id: Uuid) -> Result<Arc<Transaction>, surrealdb_types::Error> {
        self.txns
            .get(&id)
            .map(|entry| Arc::clone(entry.value()))
            .ok_or_else(|| unknown_transaction(id))
    }

    async fn set_tx(&self, id: Uuid, tx: Arc<Transaction>) -> Result<(), surrealdb_types::Error> {
        self.txns.insert(id, tx);
        Ok(())
    }

    /// Opens a client-managed transaction and returns its id. Statements join
    /// it by naming the id on their call; it stays open (and holds its write
    /// set) until `commit` or `cancel` names the id, or the owning session is
    /// detached, reset or deleted.
    async fn begin(
        &self,
        txn: Option<Uuid>,
        session_id: Uuid,
    ) -> Result<DbResult, surrealdb_types::Error> {
        if txn.is_some() {
            return Err(surrealdb_types::Error::validation(
                "Cannot begin a transaction inside another transaction".to_string(),
                Some(ValidationError::InvalidParams),
            ));
        }
        let tx = self
            .kvs
            .transaction(TransactionType::Write)
            .await
            .map_err(types_error_from_anyhow)?;
        let id = Uuid::new_v4();
        self.txns.insert(id, Arc::new(tx));
        self.txn_sessions.insert(id, session_id);
        Ok(DbResult::Other(Value::Uuid(id.into())))
    }

    /// Commits the client-managed transaction named by the call's first
    /// parameter and removes it from this connection.
    async fn commit(
        &self,
        _txn: Option<Uuid>,
        _session_id: Uuid,
        params: Array,
    ) -> Result<DbResult, surrealdb_types::Error> {
        let (_id, tx) = self.take_tx(params).await?;
        if let Err(err) = tx.commit().await {
            // The commit failed; roll back so the transaction's write set and
            // locks are released instead of lingering as finished-but-open.
            let _ = tx.cancel().await;
            return Err(types_error_from_anyhow(err));
        }
        Ok(DbResult::Other(Value::None))
    }

    /// Cancels (rolls back) the client-managed transaction named by the
    /// call's first parameter and removes it from this connection.
    async fn cancel(
        &self,
        _txn: Option<Uuid>,
        _session_id: Uuid,
        params: Array,
    ) -> Result<DbResult, surrealdb_types::Error> {
        let (_id, tx) = self.take_tx(params).await?;
        tx.cancel().await.map_err(types_error_from_anyhow)?;
        Ok(DbResult::Other(Value::None))
    }

    /// Cancels every transaction opened by [session_id]. Runs when the
    /// session is detached, reset or deleted, so a session teardown cannot
    /// leak a write transaction.
    async fn cleanup_txns(&self, session_id: &Uuid) {
        let owned = self
            .txn_sessions
            .iter()
            .filter(|entry| entry.value() == session_id)
            .map(|entry| *entry.key())
            .collect::<Vec<_>>();
        for id in owned {
            self.txn_sessions.remove(&id);
            if let Some((_, tx)) = self.txns.remove(&id) {
                let _ = tx.cancel().await;
            }
        }
    }

    // ------------------------------
    // Statement methods that must honor a transaction
    // ------------------------------

    // SurrealDB 3.3.0's own RPC handlers for `update`, `patch`, `relate` and
    // `run` take the transaction argument but ignore it: they execute through
    // `Datastore::process`, which runs outside every client-managed
    // transaction, so a statement sent inside an explicit transaction would
    // silently escape it (while `query`, `select`, `create`, ... honor it).
    // The overrides below repeat the upstream handlers statement-for-statement
    // and route through `Datastore::run` with the transaction attached.

    async fn update(
        &self,
        txn: Option<Uuid>,
        session_id: Uuid,
        params: Array,
    ) -> Result<DbResult, surrealdb_types::Error> {
        let session_lock = self.get_session(&session_id).await?;
        let session = session_lock.read().await;
        if !self.kvs().allows_query_by_subject(session.au.as_ref()) {
            return Err(method_not_allowed(Method::Update));
        }
        let (what, data) = extract_args::<(Value, Option<Value>)>(params.into_vec())
            .ok_or_else(|| invalid_params("Expected (what, data)".to_string()))?;
        let only = match &what {
            Value::RecordId(x) => !matches!(x.key, RecordIdKey::Range(_)),
            _ => false,
        };
        let data = data
            .and_then(|x| if x.is_nullish() { None } else { Some(x) })
            .map(|x| Data::ContentExpression(Expr::from_public_value(x)));
        let expr = Expr::Update(Box::new(UpdateStatement {
            only,
            what: vec![value_to_table(what)],
            data,
            output: Some(Output::After),
            with: None,
            cond: None,
            timeout: Expr::Literal(Literal::None),
            explain: None,
        }));
        self.run_statement_txn(txn, &session, Ast::single_expr(expr)).await
    }

    async fn patch(
        &self,
        txn: Option<Uuid>,
        session_id: Uuid,
        params: Array,
    ) -> Result<DbResult, surrealdb_types::Error> {
        let session_lock = self.get_session(&session_id).await?;
        let session = session_lock.read().await;
        if !self.kvs().allows_query_by_subject(session.au.as_ref()) {
            return Err(method_not_allowed(Method::Patch));
        }
        let (what, data, diff) =
            extract_args::<(Value, Option<Value>, Option<Value>)>(params.into_vec())
                .ok_or_else(|| invalid_params("Expected (what:Value, data:Value, diff:Value)".to_string()))?;
        let only = match &what {
            Value::RecordId(x) => !matches!(x.key, RecordIdKey::Range(_)),
            _ => false,
        };
        let data = data
            .and_then(|x| if x.is_nullish() { None } else { Some(x) })
            .map(|x| Data::PatchExpression(Expr::from_public_value(x)));
        let diff = matches!(diff, Some(Value::Bool(true)));
        let expr = Expr::Update(Box::new(UpdateStatement {
            only,
            what: vec![value_to_table(what)],
            data,
            output: if diff {
                Some(Output::Diff)
            } else {
                Some(Output::After)
            },
            with: None,
            cond: None,
            timeout: Expr::Literal(Literal::None),
            explain: None,
        }));
        self.run_statement_txn(txn, &session, Ast::single_expr(expr)).await
    }

    async fn relate(
        &self,
        txn: Option<Uuid>,
        session_id: Uuid,
        params: Array,
    ) -> Result<DbResult, surrealdb_types::Error> {
        let session_lock = self.get_session(&session_id).await?;
        let session = session_lock.read().await;
        if !self.kvs().allows_query_by_subject(session.au.as_ref()) {
            return Err(method_not_allowed(Method::Relate));
        }
        let (from, kind, with, data) =
            extract_args::<(Value, Value, Value, Option<Value>)>(params.into_vec())
                .ok_or_else(|| invalid_params("Expected (from:Value, kind:Value, with:Value, data:Value)".to_string()))?;
        let only = singular(&from) && singular(&with);
        let data = data
            .and_then(|x| if x.is_nullish() { None } else { Some(x) })
            .map(|x| Data::ContentExpression(Expr::from_public_value(x)));
        let expr = Expr::Relate(Box::new(RelateStatement {
            only,
            or_update: false,
            from: Expr::from_public_value(from),
            through: value_to_table(kind),
            to: Expr::from_public_value(with),
            data,
            output: Some(Output::After),
            timeout: Expr::Literal(Literal::None),
        }));
        self.run_statement_txn(txn, &session, Ast::single_expr(expr)).await
    }

    async fn run(
        &self,
        txn: Option<Uuid>,
        session_id: Uuid,
        params: Array,
    ) -> Result<DbResult, surrealdb_types::Error> {
        let session_lock = self.get_session(&session_id).await?;
        let session = session_lock.read().await;
        if !self.kvs().allows_query_by_subject(session.au.as_ref()) {
            return Err(method_not_allowed(Method::Run));
        }
        let (name, version, args) = extract_args::<(Value, Option<Value>, Option<Value>)>(
            params.into_vec(),
        )
        .ok_or_else(|| invalid_params("Expected (name:string, version:string, args:array)".to_string()))?;
        let name = match name {
            Value::String(v) => v,
            unexpected => {
                return Err(invalid_params(format!(
                    "Expected name to be string, got {unexpected:?}"
                )));
            }
        };
        let version = match version {
            Some(Value::String(v)) => Some(v),
            None | Some(Value::None | Value::Null) => None,
            unexpected => {
                return Err(invalid_params(format!(
                    "Expected version to be string, got {unexpected:?}"
                )));
            }
        };
        let args = match args {
            Some(Value::Array(args)) => {
                args.into_iter().map(Expr::from_public_value).collect::<Vec<Expr>>()
            }
            None | Some(Value::None | Value::Null) => vec![],
            unexpected => {
                return Err(invalid_params(format!(
                    "Expected args to be array, got {unexpected:?}"
                )));
            }
        };

        let segments = name.split("::").collect::<Vec<&str>>();
        let name = match segments.first() {
            Some(&"fn") => Function::Custom(segments[1..].join("::")),
            Some(&"mod") => {
                if !self
                    .kvs()
                    .get_capabilities()
                    .allows_experimental(&ExperimentalTarget::Surrealism)
                {
                    return Err(invalid_params(
                        "Experimental capability `surrealism` is not enabled".to_string(),
                    ));
                }
                let Some(name) = segments.get(1).map(|x| (*x).to_string()) else {
                    return Err(invalid_params("Expected module name".to_string()));
                };
                let sub = if segments.len() > 2 {
                    Some(segments[2..].join("::"))
                } else {
                    None
                };
                Function::Module(name, sub)
            }
            Some(&"silo") => {
                if !self
                    .kvs()
                    .get_capabilities()
                    .allows_experimental(&ExperimentalTarget::Surrealism)
                {
                    return Err(invalid_params(
                        "Experimental capability `surrealism` is not enabled".to_string(),
                    ));
                }
                let Some(org) = segments.get(1).map(|x| (*x).to_string()) else {
                    return Err(invalid_params(
                        "Expected silo organisation name".to_string(),
                    ));
                };
                let Some(pkg) = segments.get(2).map(|x| (*x).to_string()) else {
                    return Err(invalid_params("Expected silo package name".to_string()));
                };
                let Some(version) = version else {
                    return Err(invalid_params("Expected silo version".to_string()));
                };
                let mut split = version.split('.');
                let major = split.next().and_then(|s| s.parse::<u32>().ok()).ok_or_else(|| {
                    invalid_params("Expected major version (u32) in version string".to_string())
                })?;
                let minor = split.next().and_then(|s| s.parse::<u32>().ok()).ok_or_else(|| {
                    invalid_params("Expected minor version (u32) in version string".to_string())
                })?;
                let patch = split.next().and_then(|s| s.parse::<u32>().ok()).ok_or_else(|| {
                    invalid_params("Expected patch version (u32) in version string".to_string())
                })?;
                let sub = if segments.len() > 3 {
                    Some(segments[3..].join("::"))
                } else {
                    None
                };
                Function::Silo {
                    org,
                    pkg,
                    major,
                    minor,
                    patch,
                    sub,
                }
            }
            Some(&"ml") => {
                let name = segments[1..].join("::");
                Function::Model(Model {
                    name: name.into(),
                    version: version
                        .ok_or_else(|| {
                            invalid_params(
                                "Expected version to be set for model function".to_string(),
                            )
                        })?
                        .into(),
                })
            }
            _ => Function::Normal(name),
        };

        let expr = Expr::FunctionCall(Box::new(FunctionCall {
            receiver: name,
            arguments: args,
        }));
        self.run_statement_txn(txn, &session, Ast::single_expr(expr)).await
    }
}

impl SurrealFlutterConnection {
    /// Runs one parsed statement inside [txn] when given, mirroring how the
    /// core `query` handler routes through `Datastore::run`.
    async fn run_statement_txn(
        &self,
        txn: Option<Uuid>,
        session: &Session,
        ast: Ast,
    ) -> Result<DbResult, surrealdb_types::Error> {
        let transaction = match txn {
            Some(id) => Some(self.get_tx(id).await?),
            None => None,
        };
        let mut res = self
            .kvs
            .run(
                QueryRequest::new(QuerySource::Ast(ast), session)
                    .with_variables(Some(session.variables.clone()))
                    .with_optional_transaction(transaction),
            )
            .await?;
        let first = res.remove(0).result?;
        Ok(DbResult::Other(first))
    }

    /// Removes the transaction named by the first parameter of a `commit` /
    /// `cancel` call, returning its id and handle. Removing before committing
    /// means a transaction can only ever be finalized once.
    async fn take_tx(
        &self,
        params: Array,
    ) -> Result<(Uuid, Arc<Transaction>), surrealdb_types::Error> {
        let id = extract_txn_id(params)?;
        let tx = self
            .txns
            .remove(&id)
            .map(|(_, tx)| tx)
            .ok_or_else(|| unknown_transaction(id))?;
        self.txn_sessions.remove(&id);
        Ok((id, tx))
    }
}

/// Reads the transaction id argument of a `commit` / `cancel` call: a UUID
/// value, or a string parsing as one (the RPC layer also accepts strings for
/// UUID-typed arguments).
fn extract_txn_id(params: Array) -> Result<Uuid, surrealdb_types::Error> {
    let invalid = || {
        surrealdb_types::Error::validation(
            "Expected a transaction id (uuid) as the first parameter".to_string(),
            Some(ValidationError::InvalidParams),
        )
    };
    match params.into_vec().into_iter().next() {
        Some(Value::Uuid(id)) => Ok(uuid::Uuid::from(id)),
        Some(Value::String(s)) => s.parse::<Uuid>().map_err(|_| invalid()),
        _ => Err(invalid()),
    }
}

fn unknown_transaction(id: Uuid) -> surrealdb_types::Error {
    surrealdb_types::Error::validation(
        format!("Transaction '{id}' not found"),
        Some(ValidationError::InvalidParams),
    )
}

fn invalid_params(message: String) -> surrealdb_types::Error {
    surrealdb_types::Error::validation(message, Some(ValidationError::InvalidParams))
}

fn method_not_allowed(method: Method) -> surrealdb_types::Error {
    surrealdb_types::Error::not_allowed(
        format!("Method '{method}' is not allowed"),
        Some(NotAllowedError::Method {
            name: method.to_string(),
        }),
    )
}

/// Whether [value] names a single record rather than a set of them; used to
/// decide the `ONLY` semantics of a relate.
fn singular(value: &Value) -> bool {
    match value {
        Value::Object(_) => true,
        Value::RecordId(t) => !matches!(t.key, RecordIdKey::Range(_)),
        _ => false,
    }
}

/// Converts the `what` argument of a statement method into a table
/// expression; non-string values (record ids, ranges) stay value expressions.
fn value_to_table(value: Value) -> Expr {
    match value {
        Value::String(s) => Expr::Table(TableName::new(s)),
        x => Expr::from_public_value(x),
    }
}

/// Registers a fresh session on the connection and returns its id. Every
/// engine handle gets its own session so `use`, variables and authentication
/// on one engine never leak into another.
pub(crate) fn attach_session(connection: &SurrealFlutterConnection) -> Uuid {
    let id = Uuid::new_v4();
    let session = Arc::new(RwLock::new(Session::default().with_rt(true)));
    connection.set_session(id, session);
    id
}

/// Whether [opts] may attach to a connection created with [connection_opts]:
/// options are fixed when a shared connection is created, so attaching is
/// only allowed with the same options or with none at all.
pub(crate) fn opts_match(connection_opts: &Option<Options>, opts: &Option<Options>) -> bool {
    match opts {
        None => true,
        Some(opts) => connection_opts.as_ref() == Some(opts),
    }
}

/// Canonicalizes an endpoint into the form used for share-tag bookkeeping:
/// memory endpoints collapse to a single key and file-backed endpoints
/// normalize their path, so separator, drive-letter-case or relative-path
/// differences cannot defeat the endpoint equality check between attaches.
pub(crate) fn canonical_endpoint(endpoint: &str) -> String {
    if endpoint.starts_with("mem:") {
        return "memory".to_string();
    }
    let Some((scheme, rest)) = endpoint.split_once("://").or_else(|| endpoint.split_once(':')) else {
        return endpoint.to_string();
    };
    let scheme = scheme.to_ascii_lowercase();
    let rest = match scheme.as_str() {
        "surrealkv" | "rocksdb" | "file" | "indxdb" => canonicalize_local_path(rest),
        _ => rest.to_string(),
    };
    format!("{scheme}://{rest}")
}

#[cfg(not(target_arch = "wasm32"))]
fn canonicalize_local_path(path: &str) -> String {
    let path = Path::new(path);
    let absolute = std::path::absolute(path).unwrap_or_else(|_| path.to_path_buf());
    let mut out = absolute.to_string_lossy().replace('\\', "/");
    while out.len() > 1 && out.ends_with('/') {
        out.pop();
    }
    if cfg!(windows) {
        out.to_ascii_lowercase()
    } else {
        out
    }
}

#[cfg(target_arch = "wasm32")]
fn canonicalize_local_path(path: &str) -> String {
    path.to_string()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn memory_endpoints_share_one_key() {
        assert_eq!(canonical_endpoint("mem://"), "memory");
        assert_eq!(canonical_endpoint("memory"), "memory");
    }

    #[test]
    fn local_paths_are_normalized() {
        let a = canonical_endpoint("surrealkv://db/data");
        let b = canonical_endpoint("surrealkv://db/./data/");
        assert_eq!(a, b);
        if cfg!(windows) {
            assert_eq!(
                canonical_endpoint("surrealkv://C:\\App\\Data\\db"),
                canonical_endpoint("surrealkv://c:/app/data/db"),
            );
        }
    }

    #[test]
    fn different_endpoints_differ() {
        assert_ne!(
            canonical_endpoint("surrealkv://db/a"),
            canonical_endpoint("surrealkv://db/b"),
        );
        assert_ne!(
            canonical_endpoint("surrealkv://db/a"),
            canonical_endpoint("rocksdb://db/a"),
        );
    }
}
