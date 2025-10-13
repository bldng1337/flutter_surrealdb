use flutter_rust_bridge::frb;
use std::sync::Arc;
use std::time::Duration;
use tokio::sync::RwLock;

use arc_swap::ArcSwap;

use surrealdb::dbs::Session;
use surrealdb::kvs::export::Config;
use surrealdb::kvs::Datastore;
use surrealdb::rpc::format::cbor;

use surrealdb::rpc::RpcContext;
use surrealdb::sql::Value;
use tokio::sync::Semaphore;

use anyhow::{anyhow, Result};

use crate::api::connect::SurrealFlutterConnection;
use crate::api::options::Options;
use crate::frb_generated::StreamSink;

#[frb(opaque)]
pub struct SurrealFlutterEngine(RwLock<SurrealFlutterConnection>);

#[derive(Clone)]
pub enum Action {
    Create,
    Update,
    Delete,
    Unkown,
}

impl From<surrealdb::dbs::Action> for Action {
    fn from(action: surrealdb::dbs::Action) -> Self {
        match action {
            surrealdb::dbs::Action::Create => Action::Create,
            surrealdb::dbs::Action::Update => Action::Update,
            surrealdb::dbs::Action::Delete => Action::Delete,
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
    pub async fn execute(&self, data: Vec<u8>) -> Result<Vec<u8>> {
        let engine = self.0.read().await;
        let in_data = cbor::req(data.to_vec())?;
        let res =
            RpcContext::execute(&*engine, in_data.version, in_data.method, in_data.params).await?;

        let value: Value = res.try_into()?;
        let out = cbor::res(value)?;

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
                    cbor::res(notification.record),
                    cbor::res(notification.result),
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
        };

        Ok(SurrealFlutterEngine(RwLock::new(connection)))
    }

    pub async fn export(&self, config: Option<Vec<u8>>) -> Result<String> {
        let engine = self.0.read().await;
        let (tx, rx) = channel::unbounded();

        match config {
            Some(config) => {
                let in_config = cbor::parse_value(config.to_vec())?;
                let config = Config::try_from(&in_config)?;

                engine
                    .kvs
                    .export_with_config(engine.session().as_ref(), tx, config)
                    .await?
                    .await?;
            }
            None => {
                engine
                    .kvs
                    .export(engine.session().as_ref(), tx)
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

        engine.kvs.import(&input, engine.session().as_ref()).await?;

        Ok(())
    }

    pub fn version() -> Result<String> {
        Ok(env!("SURREALDB_VERSION").into())
    }
}
