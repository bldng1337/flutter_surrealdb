use flutter_rust_bridge::frb;
use std::sync::Arc;

use surrealdb_core::dbs::Session;
use surrealdb_core::kvs::Datastore;
use surrealdb_core::rpc::{DbResult, RpcProtocol};
use surrealdb_types::{HashMap, Value};
use tokio::sync::RwLock;
use uuid::Uuid;

#[frb(ignore)]
pub(crate) struct SurrealFlutterConnection {
    pub kvs: Arc<Datastore>,
    pub sessions: HashMap<Option<Uuid>, Arc<RwLock<Session>>>,
}

// #[frb(ignore)]
impl RpcProtocol for SurrealFlutterConnection {
    fn kvs(&self) -> &Datastore {
        &self.kvs
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
    fn session_map(&self) -> &HashMap<Option<Uuid>, Arc<RwLock<Session>>> {
        &self.sessions
    }

    // ------------------------------
    // Realtime
    // ------------------------------

    const LQ_SUPPORT: bool = true;

    /// Handles the execution of a LIVE statement
    async fn handle_live(&self, _lqid: &Uuid, _session_id: Option<Uuid>) {
        // async { unimplemented!("handle_live function must be implemented if LQ_SUPPORT = true") }
    }
    /// Handles the execution of a KILL statement
    async fn handle_kill(&self, _lqid: &Uuid) {
        // async { unimplemented!("handle_kill function must be implemented if LQ_SUPPORT = true") }
    }

    /// Handles the cleanup of live queries
    async fn cleanup_lqs(&self, _session_id: Option<&Uuid>) {}

    async fn cleanup_all_lqs(&self) {}
}

// impl RpcProtocolV1 for SurrealFlutterConnection {}
// impl RpcProtocolV2 for SurrealFlutterConnection {}
