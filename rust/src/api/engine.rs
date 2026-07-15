use flutter_rust_bridge::frb;
use std::sync::Arc;
use std::time::Duration;
use tokio::sync::RwLock;
use uuid::Uuid;

use surrealdb_core::dbs::Session;
pub use surrealdb_core::kvs::export::{Config, ExcludedTables, TableConfig};
use surrealdb_core::kvs::Datastore;
use surrealdb_core::rpc::format::cbor;
pub use surrealdb_core::rpc::Method;
use surrealdb_core::rpc::RpcProtocol;
use surrealdb_types::{HashMap, SurrealValue, Value};

use anyhow::Result;

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
}

impl From<surrealdb_types::Action> for Action {
    fn from(action: surrealdb_types::Action) -> Self {
        match action {
            surrealdb_types::Action::Create => Action::Create,
            surrealdb_types::Action::Update => Action::Update,
            surrealdb_types::Action::Delete => Action::Delete,
            _ => Action::Unkown,
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
        let res = RpcProtocol::execute(
            &*engine,
            None,
            session_id,
            client_session,
            method,
            params.into_array()?,
        )
        .await?;

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
                    let _ = sink.add(DBNotification {
                        id: notification.id.as_bytes().to_vec(),
                        action: notification.action.into(),
                        record: record,
                        result: result,
                    });
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
                opts.transaction_timeout.map(|qt| Duration::from_secs(qt as u64)),
            );
            builder = builder
                .with_query_timeout(opts.query_timeout.map(|qt| Duration::from_secs(qt as u64)));
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
        };

        Ok(SurrealFlutterEngine(RwLock::new(connection)))
    }

    pub async fn export(&self, config: Option<Config>, session: Option<Vec<u8>>) -> Result<String> {
        let engine = self.0.read().await;
        let (tx, rx) = channel::unbounded();
        let session = session.map(|s| Uuid::from_slice(&s)).transpose()?;
        let session_id = session.unwrap_or(engine.default_session);
        match config {
            Some(config) => {
                // let in_config = cbor::decode(&config.to_vec())?;
                // let config = Config::try_from(&in_config)?;
                let session_lock = engine.get_session(&session_id)?;
                let session = session_lock.read().await;
                engine
                    .kvs
                    .export_with_config(&session, tx, config)
                    .await?
                    .await?;
            }
            None => {
                let session_lock = engine.get_session(&session_id)?;
                let session = session_lock.read().await;
                engine.kvs.export(&session, tx).await?.await?;
            }
        };

        let mut buffer = Vec::new();
        while let Ok(item) = rx.try_recv() {
            buffer.push(item);
        }

        let result = String::from_utf8(buffer.concat().into())?;

        Ok(result)
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
