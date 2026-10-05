use std::path::Path;
use std::sync::atomic::AtomicUsize;
use std::sync::Arc;

use dashmap::DashMap;
use flutter_rust_bridge::frb;
use lazy_static::lazy_static;

use surrealdb_core::dbs::Session;
use surrealdb_core::kvs::Datastore;
use surrealdb_core::rpc::RpcProtocol;
use surrealdb_rpc::DbResult;
use surrealdb_types::{HashMap, Notification, Value};
use tokio::sync::RwLock;
use uuid::Uuid;

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
