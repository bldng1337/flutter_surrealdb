use flutter_rust_bridge::frb;
use std::sync::Arc;

use arc_swap::ArcSwap;

use dashmap::DashMap;
use surrealdb_core::dbs::Session;
use surrealdb_core::kvs::Datastore;
use surrealdb_core::rpc::{DbResult, RpcProtocol};
use surrealdb_types::Value;
use tokio::sync::Semaphore;
use uuid::Uuid;

#[frb(ignore)]
pub(crate) struct SurrealFlutterConnection {
    pub kvs: Arc<Datastore>,
    pub lock: Arc<Semaphore>,
    pub session: ArcSwap<Session>,
    pub sessions: DashMap<Uuid, Arc<Session>>,
}

// #[frb(ignore)]
impl RpcProtocol for SurrealFlutterConnection {
    fn kvs(&self) -> &Datastore {
        &self.kvs
    }

    fn lock(&self) -> Arc<Semaphore> {
        self.lock.clone()
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
    fn get_session(&self, id: Option<&Uuid>) -> Arc<Session> {
        if let Some(id) = id {
            if let Some(session) = self.sessions.get(id) {
                session.clone()
            } else {
                let session = Arc::new(Session::default());
                self.sessions.insert(*id, session.clone());
                session
            }
        } else {
            self.session.load_full()
        }
    }

    /// Mutable access to the current session for this RPC context
    fn set_session(&self, id: Option<Uuid>, session: Arc<Session>) {
        if let Some(id) = id {
            self.sessions.insert(id, session);
        } else {
            self.session.store(session);
        }
    }

    /// Mutable access to the current session for this RPC context
    fn del_session(&self, id: &Uuid) {
        self.sessions.remove(id);
    }

    /// Lists all sessions
    fn list_sessions(&self) -> Vec<Uuid> {
        self.sessions.iter().map(|x| *x.key()).collect()
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
    async fn cleanup_lqs(&self, session_id: Option<&Uuid>) {}

    async fn cleanup_all_lqs(&self) {}
}

// impl RpcProtocolV1 for SurrealFlutterConnection {}
// impl RpcProtocolV2 for SurrealFlutterConnection {}
