use flutter_rust_bridge::frb;
use std::sync::Arc;

use arc_swap::ArcSwap;

use surrealdb::dbs::Session;
use surrealdb::kvs::Datastore;
use surrealdb::rpc::RpcProtocolV1;
use surrealdb::rpc::RpcProtocolV2;

use surrealdb::rpc::{Data, RpcContext};
use surrealdb::sql::Value;
use tokio::sync::Semaphore;
use uuid::Uuid;

#[frb(ignore)]
pub(crate) struct SurrealFlutterConnection {
    pub kvs: Arc<Datastore>,
    pub lock: Arc<Semaphore>,
    pub session: ArcSwap<Session>,
}
#[frb(ignore)]
impl RpcContext for SurrealFlutterConnection {
    fn kvs(&self) -> &Datastore {
        &self.kvs
    }

    fn lock(&self) -> Arc<Semaphore> {
        self.lock.clone()
    }

    fn session(&self) -> Arc<Session> {
        self.session.load_full()
    }

    fn set_session(&self, session: Arc<Session>) {
        self.session.store(session);
    }

    fn version_data(&self) -> Data {
        Value::Strand(format!("surrealdb-{}", env!("SURREALDB_VERSION")).into()).into()
    }

    const LQ_SUPPORT: bool = true;

    fn handle_live(&self, _lqid: &Uuid) -> impl std::future::Future<Output = ()> + Send {
        async { () }
    }

    fn handle_kill(&self, _lqid: &Uuid) -> impl std::future::Future<Output = ()> + Send {
        async { () }
    }
}

impl RpcProtocolV1 for SurrealFlutterConnection {}
impl RpcProtocolV2 for SurrealFlutterConnection {}
