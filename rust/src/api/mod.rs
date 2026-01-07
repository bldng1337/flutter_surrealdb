/// flutter_rust_bridge:ignore
mod connect;
pub mod engine;
pub mod options;
// use lazy_static::lazy_static;

#[flutter_rust_bridge::frb(init)]
pub fn init_app() {
    // flutter_rust_bridge::setup_default_user_utils();
}
