use flutter_rust_bridge::frb;
use surrealdb::Value;

#[frb(ignore)]
pub struct SurrealValue {
    #[frb(ignore)]
    value: String,
}
impl From<String> for SurrealValue {
    fn from(value: String) -> Self {
        Self { value }
    }
}
impl Into<String> for SurrealValue {
    fn into(self) -> String {
        self.value
    }
}

impl TryFrom<Value> for SurrealValue {
    type Error = anyhow::Error;

    fn try_from(value: Value) -> std::result::Result<Self, Self::Error> {
        Ok(SurrealValue {
            value: serde_json::to_string(&value)?,
        })
    }
}

impl TryInto<Value> for SurrealValue {
    type Error = anyhow::Error;

    fn try_into(self) -> std::result::Result<Value, Self::Error> {
        Ok(serde_json::from_str(&self.value)?)
    }
}
