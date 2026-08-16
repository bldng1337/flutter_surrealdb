use std::sync::Arc;

use dashmap::DashMap;
use flutter_rust_bridge::frb;

use surrealdb_core::dbs::Session;
use surrealdb_core::kvs::Datastore;
use surrealdb_core::rpc::{DbResult, RpcProtocol};
use surrealdb_types::{HashMap, Notification, Value};
use tokio::sync::RwLock;
use uuid::Uuid;

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

#[frb(ignore)]
pub(crate) struct SurrealFlutterConnection {
	pub kvs: Arc<Datastore>,
	pub sessions: HashMap<Uuid, Arc<RwLock<Session>>>,
	pub default_session: Uuid,
	pub notifications: channel::Receiver<Notification>,
	/// Live queries created through this connection, keyed by live query id.
	pub live_queries: DashMap<Uuid, TrackedLiveQuery>,
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
			let _ = self.kvs.execute(&kill, &session, None).await;
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

	/// Forgets a live query once it has been killed.
	async fn handle_kill(&self, lqid: &Uuid) {
		self.live_queries.remove(lqid);
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
}
