use flutter_rust_bridge::frb;
use arc_swap::ArcSwapOption;
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::Arc;
use std::time::Duration;
use dashmap::DashMap;
use tokio::sync::RwLock;
use uuid::Uuid;

pub use surrealdb_rpc::export::{Config, ExcludedTables, TableConfig};
use surrealdb_core::kvs::Datastore;
use surrealdb_core::rpc::format::cbor;
pub use surrealdb_rpc::Method;
use surrealdb_core::rpc::RpcProtocol;
use surrealdb_rpc::DbResult;
use surrealdb_types::{ErrorDetails, HashMap, NotFoundError, QueryError, SurrealValue, Value};

use anyhow::{anyhow, Result};

use crate::api::connect::{
    attach_session, canonical_endpoint, opts_match, NotificationHub, SurrealFlutterConnection,
    SHARED_CONNECTIONS, SHARED_CONNECT_LOCK,
};
use crate::api::options::Options;
use crate::frb_generated::StreamSink;

/// A handle to a [`SurrealFlutterConnection`].
///
/// Handles created without a share tag each own their connection (and with
/// it, the file lock of the underlying database). Handles created with a
/// share tag all point at one process-wide connection registered under that
/// tag, so other isolates of the same process can attach to an already open
/// database instead of failing on its file lock. Every handle carries its
/// own session, so `use`, variables and authentication never leak between
/// handles even on a shared connection.
#[frb(opaque)]
pub struct SurrealFlutterEngine {
    /// The connection this handle is attached to; `None` once the handle has
    /// been closed. Kept behind an swappable Option so `close` can drop the
    /// reference eagerly: otherwise the connection (and with it the file
    /// lock) would survive until the Dart side garbage collects the handle.
    connection: ArcSwapOption<SurrealFlutterConnection>,
    default_session: Uuid,
    share_tag: Option<String>,
    /// Guards against a double lease release when close() runs before Drop.
    released: AtomicBool,
}

#[frb(mirror(Config))]
pub struct _Config {
    pub users: bool,
    pub accesses: bool,
    pub params: bool,
    pub functions: bool,
    pub analyzers: bool,
    pub apis: bool,
    pub buckets: bool,
    pub modules: bool,
    pub configs: bool,
    pub tables: TableConfig,
    pub versions: bool,
    pub records: bool,
    pub sequences: bool,
}

#[frb(mirror(ExcludedTables))]
pub struct _ExcludedTables {
    pub exclude: Vec<String>,
}

#[frb(mirror(TableConfig))]
pub enum _TableConfig {
    All,
    None,
    Some(Vec<String>),
    Exclude(ExcludedTables),
}

#[frb(mirror(Method))]
pub enum _Method {
    Unknown,
    Ping,
    Info,
    Use,
    Signup,
    Signin,
    Authenticate,
    Refresh,
    Invalidate,
    Revoke,
    Reset,
    Kill,
    Live,
    Set,
    Unset,
    Select,
    Insert,
    Create,
    Upsert,
    Update,
    Merge,
    Patch,
    Delete,
    Version,
    Query,
    Gql,
    Graphql,
    Relate,
    Run,
    InsertRelation,
    Attach,
    Sessions,
    Detach,
    Begin,
    Commit,
    Cancel,
}

#[derive(Clone)]
pub enum Action {
    Create,
    Update,
    Delete,
    Unkown,
    Killed,
    Error,
}

impl From<surrealdb_types::Action> for Action {
    fn from(action: surrealdb_types::Action) -> Self {
        match action {
            surrealdb_types::Action::Create => Action::Create,
            surrealdb_types::Action::Update => Action::Update,
            surrealdb_types::Action::Delete => Action::Delete,
            surrealdb_types::Action::Killed => Action::Killed,
            surrealdb_types::Action::Error => Action::Error,
        }
    }
}

pub struct DBNotification {
    // pub id: uuid::Uu
    pub id: Vec<u8>,
    pub action: Action,
    pub record: Vec<u8>,
    pub result: Vec<u8>,
}

impl SurrealFlutterEngine {
    /// The connection this handle is attached to, or an error once the
    /// handle has been closed.
    fn conn(&self) -> Result<Arc<SurrealFlutterConnection>> {
        self.connection
            .load_full()
            .ok_or_else(|| anyhow!("engine handle is closed"))
    }

    pub async fn execute(
        &self,
        method: Method,
        params: Vec<u8>,
        session: Option<Vec<u8>>,
        txn: Option<Vec<u8>>,
    ) -> Result<Vec<u8>> {
        let connection = self.conn()?;
        let engine = connection.as_ref();
        let params = cbor::decode(&params, 128)?;
        let client_session = session.map(|s| Uuid::from_slice(&s)).transpose()?;
        let session_id = client_session.unwrap_or(self.default_session);
        let params = params.into_array()?;
        let txn = txn.map(|t| Uuid::from_slice(&t)).transpose()?;

        // Concurrent statements on one datastore race their write
        // transactions; on an optimistic backend like surrealkv the loser
        // comes back with a transaction conflict instead of blocking. A
        // conflicted statement was rolled back whole, so it is retried here
        // with a short backoff rather than surfacing the conflict to the
        // client (two engines attaching to one connection and both starting
        // a live query is enough to hit it). Excluded from the retry:
        // statements joining a client-managed transaction, and commit/cancel
        // - their handler removes the transaction before finalizing it, so a
        // conflict there has already consumed it and cannot be replayed.
        let mut attempt = 0u32;
        let res = loop {
            match RpcProtocol::execute(
                engine,
                txn,
                session_id,
                client_session,
                method,
                params.clone(),
            )
            .await
            {
                Ok(res) => break res,
                Err(err)
                    if txn.is_none()
                        && !matches!(method, Method::Commit | Method::Cancel)
                        && is_transaction_conflict(&err) =>
                {
                    attempt += 1;
                    if attempt > MAX_CONFLICT_RETRIES {
                        return Err(err.into());
                    }
                    tokio::time::sleep(CONFLICT_RETRY_BACKOFF * attempt).await;
                }
                // SurrealDB 3.x requires a table to exist before SELECT/LIVE can
                // run against it, so a table that was never written to or defined
                // fails with NotFoundError::Table. Normalize this at the bridge so
                // a table that simply doesn't exist yet behaves like an empty
                // table, matching the pre-3.x behaviour of this engine.
                Err(err) if is_missing_table(&err) => {
                    break missing_table_fallback(
                        engine,
                        err,
                        method,
                        &params,
                        session_id,
                        client_session,
                        txn,
                    )
                    .await?
                }
                Err(err) => return Err(err.into()),
            }
        };

        let value: Value = res.into_value();
        let out = cbor::encode(value)?;

        Ok(out.as_slice().into())
    }

    pub async fn notifications(&self, sink: StreamSink<DBNotification>) -> Result<()> {
        let receiver = self.conn()?.notifications.subscribe();
        // Spawn a task to process notifications

        tokio::spawn(async move {
            while let Ok(notification) = receiver.recv().await {
                if let (Ok(record), Ok(result)) = (
                    cbor::encode(notification.record),
                    cbor::encode(notification.result),
                ) {
                    // Stop draining the channel once the Dart side has
                    // cancelled the stream, otherwise this task would keep
                    // running forever.
                    if sink
                        .add(DBNotification {
                            id: notification.id.as_bytes().to_vec(),
                            action: notification.action.into(),
                            record: record,
                            result: result,
                        })
                        .is_err()
                    {
                        break;
                    }
                }
            }
        });

        Ok(())
    }

    /// Connects to a SurrealDB instance.
    ///
    /// Without [share_tag] the returned handle owns a private connection.
    /// With [share_tag] the handle attaches to the process-wide connection
    /// registered under that tag, creating it if needed; this is what allows
    /// other isolates to use the same database even though its file is locked
    /// by the first connection. Attaching is rejected when the tag is already
    /// registered with a different endpoint or different options.
    pub async fn connect(
        endpoint: String,
        opts: Option<Options>,
        share_tag: Option<String>,
    ) -> Result<SurrealFlutterEngine> {
        let canonical = canonical_endpoint(&endpoint);

        let connection = if let Some(tag) = share_tag.as_deref() {
            let _guard = SHARED_CONNECT_LOCK.lock().await;
            if let Some(entry) = SHARED_CONNECTIONS.get(tag) {
                let existing = Arc::clone(entry.value());
                drop(entry);
                if existing.endpoint != canonical {
                    return Err(anyhow!(
                        "share tag '{tag}' is already open with endpoint '{}'; \
                         close it or use a different tag",
                        existing.endpoint
                    ));
                }
                if !opts_match(&existing.opts, &opts) {
                    return Err(anyhow!(
                        "share tag '{tag}' is already open with different options; \
                         the options of a shared connection are fixed at creation"
                    ));
                }
                existing.leases.fetch_add(1, Ordering::SeqCst);
                existing
            } else {
                let connection =
                    build_connection(&endpoint, canonical.clone(), opts).await?;
                connection.leases.store(1, Ordering::SeqCst);
                SHARED_CONNECTIONS.insert(tag.to_string(), Arc::clone(&connection));
                connection
            }
        } else {
            build_connection(&endpoint, canonical, opts).await?
        };

        let default_session = attach_session(&connection);

        Ok(SurrealFlutterEngine {
            connection: ArcSwapOption::from(Some(connection)),
            default_session,
            share_tag,
            released: AtomicBool::new(false),
        })
    }

    /// Releases this engine handle: its session is removed (killing the live
    /// queries created through it) and, for shared connections, its lease is
    /// dropped. When the last handle of a shared connection is released, the
    /// connection is deregistered and its datastore, together with the file
    /// lock, is dropped.
    pub async fn close(&self) -> Result<()> {
        let Some(connection) = self.connection.load_full() else {
            return Ok(());
        };
        // Session teardown must not block the lease release below; the
        // result was ignored before 3.3 made del_session fallible too.
        let _ = connection.del_session(&self.default_session).await;

        // For shared connections, serialize the release against concurrent
        // attaches with the same tag: an attach that misses the registry in
        // the window between this handle's lease release and the file lock
        // actually being freed would try to build a second datastore and
        // fail on that lock.
        let _guard = if self.share_tag.is_some() {
            Some(SHARED_CONNECT_LOCK.lock().await)
        } else {
            None
        };
        self.release();
        // Drop this handle's reference eagerly rather than waiting for the
        // Dart-side handle to be garbage collected, so the datastore and its
        // file lock are released as soon as the last reference goes away.
        self.connection.store(None);
        // With this handle's own reference dropped, a count of one means
        // only the local borrow remains: this is the final handle, so stop
        // the datastore's background workers (surrealkv flusher and commit
        // coordinator) for a deterministic release of the file lock.
        if Arc::strong_count(&connection) == 1 {
            let _ = connection.kvs.shutdown().await;
        }
        Ok(())
    }

    /// Releases this handle's lease on a shared connection and, if it was the
    /// last one, deregisters the connection. Idempotent, and also invoked
    /// from `Drop` for handles that were never closed explicitly.
    fn release(&self) {
        if self.released.swap(true, Ordering::SeqCst) {
            return;
        }
        let Some(tag) = &self.share_tag else {
            return;
        };
        let Some(connection) = self.connection.load_full() else {
            return;
        };
        if connection.leases.fetch_sub(1, Ordering::SeqCst) == 1 {
            // While a lease was held no other connect could have replaced
            // the registry entry, but the pointer check keeps this safe even
            // if that invariant ever changes.
            let _ =
                SHARED_CONNECTIONS.remove_if(tag, |_, conn| Arc::ptr_eq(conn, &connection));
        }
    }

    /// Streams the database export to [sink] in chunks instead of buffering
    /// the whole export in memory. Cancelling the Dart-side stream aborts the
    /// export.
    pub async fn export_stream(
        &self,
        config: Option<Config>,
        session: Option<Vec<u8>>,
        sink: StreamSink<Vec<u8>>,
    ) -> Result<()> {
        let connection = self.conn()?;
        let engine = connection.as_ref();
        let (tx, rx) = channel::unbounded();
        let session = session.map(|s| Uuid::from_slice(&s)).transpose()?;
        let session_id = session.unwrap_or(self.default_session);
        let session = engine.get_session(&session_id).await?.read().await.clone();
        let kvs = engine.kvs_arc();

        // Run the export in a task so chunks can be forwarded while it is
        // still producing. The channel closes once the export finishes and
        // its sender is dropped, which ends the forwarding loop below.
        let export = tokio::spawn(async move {
            match config {
                Some(config) => {
                    kvs.export_with_config(&session, tx, config)
                        .await?
                        .await?
                }
                None => kvs.export(&session, tx).await?.await?,
            }
            Ok::<(), anyhow::Error>(())
        });

        while let Ok(item) = rx.recv().await {
            if sink.add(item).is_err() {
                // The Dart side cancelled the stream; abort the export.
                export.abort();
                return Ok(());
            }
        }

        export.await??;
        Ok(())
    }

    pub async fn import(&self, input: String, session: Option<Vec<u8>>) -> Result<()> {
        let connection = self.conn()?;
        let engine = connection.as_ref();
        let session = session.map(|s| Uuid::from_slice(&s)).transpose()?;
        let session_id = session.unwrap_or(self.default_session);
        let session_lock = engine.get_session(&session_id).await?;
        let session = session_lock.read().await;
        engine.kvs.import(&input, &session).await?;

        Ok(())
    }

    pub async fn create_session(&self) -> Result<Vec<u8>> {
        let connection = self.conn()?;
        Ok(attach_session(&connection).into_bytes().to_vec())
    }

    pub async fn fork_session(&self, id: Vec<u8>) -> Result<Vec<u8>> {
        let connection = self.conn()?;
        let engine = connection.as_ref();
        let id = Uuid::from_slice(&id)?;
        let session_lock = engine.get_session(&id).await?;
        let session = session_lock.read().await.clone();
        let session = Arc::new(RwLock::new(session));
        let new_id = Uuid::new_v4();
        engine.set_session(new_id, session);
        Ok(new_id.as_bytes().to_vec())
    }

    pub async fn close_session(&self, id: Vec<u8>) -> Result<()> {
        let connection = self.conn()?;
        let engine = connection.as_ref();
        let id = Uuid::from_slice(&id)?;
        engine.del_session(&id).await?;
        Ok(())
    }

    pub fn version() -> Result<String> {
        Ok(env!("SURREALDB_VERSION").into())
    }
}

impl Drop for SurrealFlutterEngine {
    fn drop(&mut self) {
        // Fallback for handles that were never closed explicitly (for
        // example an isolate that died without disposing): releasing the
        // lease keeps a forgotten handle from pinning the shared connection,
        // and with it the file lock, forever. The session entry and live
        // queries of such a handle stay alive until the connection itself is
        // dropped; [SurrealFlutterEngine::close] is the deterministic
        // cleanup path.
        self.release();
    }
}

/// Opens a new private connection. The endpoint is parsed by the datastore
/// builder; [canonical] is its normalized form for share-tag bookkeeping.
async fn build_connection(
    endpoint: &str,
    canonical: String,
    opts: Option<Options>,
) -> Result<Arc<SurrealFlutterConnection>> {
    let endpoint = match endpoint {
        s if s.starts_with("mem:") => "memory",
        s => s,
    };

    let (notify_tx, notify_rx) = channel::unbounded();
    let mut builder = Datastore::builder().with_notify(notify_tx);

    if let Some(opts) = &opts {
        builder = builder.with_capabilities(
            opts.capabilities
                .clone()
                .map_or(Ok(Default::default()), |a| a.try_into())?,
        );
        builder = builder.with_transaction_timeout(
            opts.transaction_timeout.map(|t| Duration::from_millis(t.into())),
        );
        builder =
            builder.with_query_timeout(opts.query_timeout.map(|t| Duration::from_millis(t.into())));
    }

    let kvs = builder.build_with_path(endpoint).await?;

    let connection = Arc::new(SurrealFlutterConnection {
        kvs,
        sessions: HashMap::new(),
        notifications: Arc::new(NotificationHub::new()),
        live_queries: DashMap::new(),
        txns: DashMap::new(),
        txn_sessions: DashMap::new(),
        endpoint: canonical,
        opts,
        leases: std::sync::atomic::AtomicUsize::new(0),
    });

    let drainer = Arc::downgrade(&connection);
    tokio::spawn(async move {
        // The single drainer for this datastore: async-channel receivers are
        // competing consumers, so exactly one task may receive here, and it
        // fans every notification out to each subscriber. The link to the
        // connection must stay weak: the loop only ends when the datastore is
        // dropped (its sender drops with it), and a strong reference here
        // would keep that datastore - and with a file-backed endpoint, its
        // lock - alive forever. The loop therefore ends either when the
        // channel closes or when the upgrade finds the connection already
        // gone; a notification outliving its connection is dropped.
        while let Ok(notification) = notify_rx.recv().await {
            let Some(drainer) = drainer.upgrade() else {
                break;
            };
            // 3.3 dropped the RpcProtocol::handle_kill hook; the killed live
            // query's id is only reported through its Action::Killed
            // notification, so the tracking entry is dropped here.
            if notification.action == surrealdb_types::Action::Killed {
                drainer.live_queries.remove(&notification.id);
            }
            drainer.notifications.broadcast(notification);
        }
    });

    Ok(connection)
}

/// How often a call that lost a transaction-conflict race is retried before
/// the conflict is surfaced to the client.
const MAX_CONFLICT_RETRIES: u32 = 5;

/// Base delay between conflict retries; grows linearly with the attempt.
const CONFLICT_RETRY_BACKOFF: Duration = Duration::from_millis(10);

/// Whether [err] is a transaction conflict: the call's transaction raced a
/// concurrent writer and was rolled back whole, so rerunning it cannot
/// double-apply anything.
pub(crate) fn is_transaction_conflict(err: &surrealdb_types::Error) -> bool {
    matches!(err.query_details(), Some(QueryError::TransactionConflict))
}

/// Whether [err] is the SurrealDB 3.x "table does not exist" error, raised
/// when a SELECT/LIVE statement targets a table that was never defined or
/// written to.
fn is_missing_table(err: &surrealdb_types::Error) -> bool {
    matches!(
        err.details(),
        ErrorDetails::NotFound(Some(NotFoundError::Table { .. }))
    )
}

/// Recovers from a missing-table error for [method]:
/// - `select`: returns NONE for a record id and an empty array for a table,
/// like the pre-3.x engine did.
/// - `live`: implicitly creates the missing table (as a plain schemaless
/// table) and retries the statement once, so a live query can be started on
/// a table that doesn't exist yet and fires once records are created.
///
/// Any other error, method or parameter shape is propagated unchanged.
async fn missing_table_fallback(
    engine: &SurrealFlutterConnection,
    err: surrealdb_types::Error,
    method: Method,
    params: &[Value],
    session_id: Uuid,
    client_session: Option<Uuid>,
    txn: Option<Uuid>,
) -> Result<DbResult> {
    let what = params.first();
    match (method, what) {
        (Method::Select, Some(Value::RecordId(_))) => Ok(DbResult::Other(Value::None)),
        (Method::Select, Some(_)) => {
            Ok(DbResult::Other(Value::Array(Vec::<Value>::new().into())))
        }
        (Method::Live, Some(Value::Table(table))) => {
            create_missing_table(engine, table.as_str(), session_id).await?;
            retry(engine, method, params, session_id, client_session, txn).await
        }
        // The RPC layer also accepts a plain string as a table name.
        (Method::Live, Some(Value::String(table))) => {
            create_missing_table(engine, table, session_id).await?;
            retry(engine, method, params, session_id, client_session, txn).await
        }
        _ => Err(err.into()),
    }
}

async fn create_missing_table(
    engine: &SurrealFlutterConnection,
    table: &str,
    session_id: Uuid,
) -> Result<()> {
    let session_lock = engine
        .get_session(&session_id)
        .await
        .map_err(|e| anyhow!(e.to_string()))?;
    let session = session_lock.read().await.clone();
    let define = format!("DEFINE TABLE IF NOT EXISTS {}", escape_surreal_ident(table));
    // The implicit-table creation can race a concurrent writer; a conflicted
    // DEFINE was rolled back whole, so retrying it is safe.
    let mut attempt = 0u32;
    loop {
        match engine.kvs.execute(&define, &session, None).await {
            Err(err) if attempt < MAX_CONFLICT_RETRIES && is_transaction_conflict(&err) => {
                attempt += 1;
                tokio::time::sleep(CONFLICT_RETRY_BACKOFF * attempt).await;
            }
            res => return res.map(|_| ()).map_err(Into::into),
        }
    }
}

async fn retry(
    engine: &SurrealFlutterConnection,
    method: Method,
    params: &[Value],
    session_id: Uuid,
    client_session: Option<Uuid>,
    txn: Option<Uuid>,
) -> Result<DbResult> {
    Ok(RpcProtocol::execute(
        engine,
        txn,
        session_id,
        client_session,
        method,
        params.to_vec().into(),
    )
    .await?)
}

/// Quotes [ident] as a backtick-delimited SurrealQL identifier, escaping
/// backticks and backslashes.
pub(crate) fn escape_surreal_ident(ident: &str) -> String {
    let mut out = String::with_capacity(ident.len() + 2);
    out.push('`');
    for c in ident.chars() {
        if c == '`' || c == '\\' {
            out.push('\\');
        }
        out.push(c);
    }
    out.push('`');
    out
}
