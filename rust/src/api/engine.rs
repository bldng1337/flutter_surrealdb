use flutter_rust_bridge::frb;
use std::sync::Arc;
use std::time::Duration;
use tokio::sync::RwLock;

use arc_swap::ArcSwap;
use dashmap::DashMap;
use surrealdb_core::dbs::Session;
pub use surrealdb_core::kvs::export::{Config, TableConfig};
use surrealdb_core::kvs::{Datastore, LockType, TransactionType};
use surrealdb_core::rpc::format::cbor;
pub use surrealdb_core::rpc::Method;
use surrealdb_core::rpc::{RpcError, RpcProtocol};
use surrealdb_types::{Array, SurrealValue, Value};
use tokio::sync::Semaphore;

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
    pub tables: TableConfig,
    pub versions: bool,
    pub records: bool,
    pub sequences: bool,
}

#[frb(mirror(TableConfig))]
pub enum _TableConfig {
    All,
    None,
    Some(Vec<String>),
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
    Invalidate,
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
    Relate,
    Run,
    InsertRelation,
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
        version: Option<u8>,
    ) -> Result<Vec<u8>> {
        let engine = self.0.read().await;
        let params = cbor::decode(&params)?;
        let res = RpcProtocol::execute(&*engine, None, None, method, params.into_array()?).await?;

        let value: Value = res.into_value();
        let out = cbor::encode(value)?;

        Ok(out.as_slice().into())
    }

    pub async fn notifications(&self, sink: StreamSink<DBNotification>) -> Result<()> {
        let stream = {
            let engine = self.0.read().await;

            engine
                .kvs
                .notifications()
                .ok_or_else(|| anyhow!("Notifications not enabled"))?
        };
        // Spawn a task to process notifications

        tokio::spawn(async move {
            let notification_stream = stream;
            let sink = sink;

            while let Ok(notification) = notification_stream.recv().await {
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

        let kvs = Datastore::new(endpoint).await?.with_notifications();
        let kvs = match opts {
            None => kvs,
            Some(opts) => kvs
                .with_capabilities(
                    opts.capabilities
                        .map_or(Ok(Default::default()), |a| a.try_into())?,
                )
                .with_transaction_timeout(
                    opts.transaction_timeout
                        .map(|qt| Duration::from_secs(qt as u64)),
                )
                .with_query_timeout(opts.query_timeout.map(|qt| Duration::from_secs(qt as u64)))
                .with_strict_mode(opts.strict.map_or(Default::default(), |s| s)),
        };

        let session = Session::default().with_rt(true);

        let connection = SurrealFlutterConnection {
            kvs: Arc::new(kvs),
            session: ArcSwap::new(Arc::new(session)),
            lock: Arc::new(Semaphore::new(1)),
            sessions: DashMap::new(),
        };

        Ok(SurrealFlutterEngine(RwLock::new(connection)))
    }

    pub async fn export(&self, config: Option<Config>) -> Result<String> {
        let engine = self.0.read().await;
        let (tx, rx) = channel::unbounded();

        match config {
            Some(config) => {
                // let in_config = cbor::decode(&config.to_vec())?;
                // let config = Config::try_from(&in_config)?;
                engine
                    .kvs
                    .export_with_config(engine.get_session(None).as_ref(), tx, config)
                    .await?
                    .await?;
            }
            None => {
                engine
                    .kvs
                    .export(engine.get_session(None).as_ref(), tx)
                    .await?
                    .await?;
            }
        };

        let mut buffer = Vec::new();
        while let Ok(item) = rx.try_recv() {
            buffer.push(item);
        }

        let result = String::from_utf8(buffer.concat().into())?;

        Ok(result)
    }

    pub async fn import(&self, input: String) -> Result<()> {
        let engine = self.0.read().await;

        engine
            .kvs
            .import(&input, engine.get_session(None).as_ref())
            .await?;

        Ok(())
    }

    pub fn version() -> Result<String> {
        Ok(env!("SURREALDB_VERSION").into())
    }
}
