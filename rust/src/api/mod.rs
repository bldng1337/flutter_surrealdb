/// flutter_rust_bridge:ignore
mod connect;
pub mod engine;
pub mod options;
// use lazy_static::lazy_static;

//TODO: Needed for web
// #[cfg(not(target_family = "wasm"))]
// lazy_static! {
//     pub static ref FLUTTER_RUST_BRIDGE_HANDLER: flutter_rust_bridge::DefaultHandler<flutter_rust_bridge::for_generated::SimpleThreadPool> =
//         flutter_rust_bridge::DefaultHandler::new_simple(Default::default());
// }

// #[cfg(target_family = "wasm")]
// thread_local! {
//     pub static THREAD_POOL: flutter_rust_bridge::for_generated::SimpleThreadPool = Default::default();
// }

// #[cfg(target_family = "wasm")]
// flutter_rust_bridge::for_generated::lazy_static! {
//     pub static ref FLUTTER_RUST_BRIDGE_HANDLER: $flutter_rust_bridge::DefaultHandler<&'static std::thread::LocalKey<$flutter_rust_bridge::for_generated::SimpleThreadPool>>
//         = $flutter_rust_bridge::DefaultHandler::new_simple(&THREAD_POOL);
// }

#[flutter_rust_bridge::frb(init)]
pub fn init_app() {
    // flutter_rust_bridge::setup_default_user_utils();
}
