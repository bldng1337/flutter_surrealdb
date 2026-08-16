use flutter_rust_bridge::frb;
use std::sync::Arc;
use std::time::Duration;
use dashmap::DashMap;
use tokio::sync::RwLock;
use uuid::Uuid;

use surrealdb_core::dbs::Session;
pub use surrealdb_core::kvs::export::{Config, ExcludedTables, TableConfig};
use surrealdb_core::kvs::Datastore;
use surrealdb_core::rpc::format::cbor;
pub use surrealdb_core::rpc::Method;
use surrealdb_core::rpc::{DbResult, RpcProtocol};
use surrealdb_types::{ErrorDetails, HashMap, NotFoundError, SurrealValue, Value};

use anyhow::{anyhow, Result};

use crate::api::connect::SurrealFlutterConnection;
use crate::api::options::Options;
use crate::frb_generated::StreamSink;

#[frb(opaque)]
pub struct SurrealFlutterEngine(RwLock<SurrealFlutterConnection>);

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
    pub async fn execute(
        &self,
        method: Method,
        params: Vec<u8>,
        session: Option<Vec<u8>>,
    ) -> Result<Vec<u8>> {
        let engine = self.0.read().await;
        let params = cbor::decode(&params, 128)?;
        let client_session = session.map(|s| Uuid::from_slice(&s)).transpose()?;
        let session_id = client_session.unwrap_or(engine.default_session);
        let params = params.into_array()?;

        let res = match RpcProtocol::execute(
            &*engine,
            None,
            session_id,
            client_session,
            method,
            params.clone(),
        )
        .await
        {
            Ok(res) => res,
            // SurrealDB 3.x requires a table to exist before SELECT/LIVE can
            // run against it, so a table that was never written to or defined
            // fails with NotFoundError::Table. Normalize this at the bridge so
            // a table that simply doesn't exist yet behaves like an empty
            // table, matching the pre-3.x behaviour of this engine.
            Err(err) if is_missing_table(&err) => missing_table_fallback(
                &engine,
                err,
                method,
                &params,
                session_id,
                client_session,
            )
            .await?,
            Err(err) => return Err(err.into()),
        };

        let value: Value = res.into_value();
        let out = cbor::encode(value)?;

        Ok(out.as_slice().into())
    }

    pub async fn notifications(&self, sink: StreamSink<DBNotification>) -> Result<()> {
        let receiver = {
            let engine = self.0.read().await;
            engine.notifications.clone()
        };
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

    pub async fn connect(endpoint: String, opts: Option<Options>) -> Result<SurrealFlutterEngine> {
        let endpoint = match &endpoint {
            s if s.starts_with("mem:") => "memory",
            s => s,
        };

        let (notify_tx, notify_rx) = channel::unbounded();
        let mut builder = Datastore::builder().with_notify(notify_tx);

        if let Some(opts) = opts {
            builder = builder.with_capabilities(
                opts.capabilities
                    .map_or(Ok(Default::default()), |a| a.try_into())?,
            );
            builder = builder.with_transaction_timeout(
                opts.transaction_timeout.map(|t| Duration::from_millis(t.into())),
            );
            builder =
                builder.with_query_timeout(opts.query_timeout.map(|t| Duration::from_millis(t.into())));
        }

        let kvs = builder.build_with_path(endpoint).await?;

        let session = Session::default().with_rt(true);
        let sessions = HashMap::new();
        let default_id = Uuid::new_v4();
        sessions.insert(default_id, Arc::new(RwLock::new(session)));
        let connection = SurrealFlutterConnection {
            kvs: Arc::new(kvs),
            sessions,
            default_session: default_id,
            notifications: notify_rx,
            live_queries: DashMap::new(),
        };

        Ok(SurrealFlutterEngine(RwLock::new(connection)))
    }

    /// Streams the database export to [sink] in chunks instead of buffering
    /// the whole export in memory. Cancelling the Dart-side stream aborts
    /// the export.
    pub async fn export_stream(
        &self,
        config: Option<Config>,
        session: Option<Vec<u8>>,
        sink: StreamSink<Vec<u8>>,
    ) -> Result<()> {
        let engine = self.0.read().await;
        let (tx, rx) = channel::unbounded();
        let session = session.map(|s| Uuid::from_slice(&s)).transpose()?;
        let session_id = session.unwrap_or(engine.default_session);
        let session = engine.get_session(&session_id)?.read().await.clone();
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
        let engine = self.0.read().await;
        let session = session.map(|s| Uuid::from_slice(&s)).transpose()?;
        let session_id = session.unwrap_or(engine.default_session);
        let session_lock = engine.get_session(&session_id)?;
        let session = session_lock.read().await;
        engine.kvs.import(&input, &session).await?;

        Ok(())
    }

    pub async fn create_session(&self) -> Vec<u8> {
        let engine = self.0.read().await;
        let id = Uuid::new_v4();
        let session = Session::default().with_rt(true);
        let session = Arc::new(RwLock::new(session));
        engine.set_session(id, session);
        id.as_bytes().to_vec()
    }

    pub async fn fork_session(&self, id: Vec<u8>) -> Result<Vec<u8>> {
        let engine = self.0.read().await;
        let id = Uuid::from_slice(&id)?;
        let session_lock = engine.get_session(&id)?;
        let session = session_lock.read().await.clone();
        let session = Arc::new(RwLock::new(session));
        let new_id = Uuid::new_v4();
        engine.set_session(new_id, session);
        Ok(new_id.as_bytes().to_vec())
    }

    pub async fn close_session(&self, id: Vec<u8>) -> Result<()> {
        let engine = self.0.read().await;
        let id = Uuid::from_slice(&id)?;
        engine.del_session(&id).await;
        Ok(())
    }

    pub fn version() -> Result<String> {
        Ok(env!("SURREALDB_VERSION").into())
    }
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
///   like the pre-3.x engine did.
/// - `live`: implicitly creates the missing table (as a plain schemaless
///   table) and retries the statement once, so a live query can be started on
///   a table that doesn't exist yet and fires once records are created.
///
/// Any other error, method or parameter shape is propagated unchanged.
async fn missing_table_fallback(
    engine: &SurrealFlutterConnection,
    err: surrealdb_types::Error,
    method: Method,
    params: &[Value],
    session_id: Uuid,
    client_session: Option<Uuid>,
) -> Result<DbResult> {
    let what = params.first();
    match (method, what) {
        (Method::Select, Some(Value::RecordId(_))) => Ok(DbResult::Other(Value::None)),
        (Method::Select, Some(_)) => {
            Ok(DbResult::Other(Value::Array(Vec::<Value>::new().into())))
        }
        (Method::Live, Some(Value::Table(table))) => {
            create_missing_table(engine, table.as_str(), session_id).await?;
            retry(engine, method, params, session_id, client_session).await
        }
        // The RPC layer also accepts a plain string as a table name.
        (Method::Live, Some(Value::String(table))) => {
            create_missing_table(engine, table, session_id).await?;
            retry(engine, method, params, session_id, client_session).await
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
        .map_err(|e| anyhow!(e.to_string()))?;
    let session = session_lock.read().await.clone();
    let define = format!("DEFINE TABLE IF NOT EXISTS {}", escape_surreal_ident(table));
    engine.kvs.execute(&define, &session, None).await?;
    Ok(())
}

async fn retry(
    engine: &SurrealFlutterConnection,
    method: Method,
    params: &[Value],
    session_id: Uuid,
    client_session: Option<Uuid>,
) -> Result<DbResult> {
    Ok(RpcProtocol::execute(
        engine,
        None,
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
