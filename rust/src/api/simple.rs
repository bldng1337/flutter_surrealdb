use std::collections::HashMap;

use crate::frb_generated::StreamSink;
pub use crate::private::wrapper::SurrealValue;
use anyhow::Context;
use anyhow::Result;
use flutter_rust_bridge::frb;
use futures::stream::StreamExt;
use surrealdb::engine::local::Db;
use surrealdb::engine::local::Mem;
use surrealdb::engine::local::SurrealKv;
use surrealdb::opt::auth::Record;
use surrealdb::opt::Resource;
use surrealdb::Action as SurrealAction;
use surrealdb::Notification;
use surrealdb::RecordId;
use surrealdb::Value;

#[frb(rust2dart(dart_type = "dynamic", dart_code = "surrencodeType({})"))]
pub fn encode_fancy_type(raw: SurrealValue) -> String {
    raw.into()
}

#[frb(dart2rust(dart_type = "dynamic", dart_code = "surrdecodeType({})"))]
pub fn decode_fancy_type(raw: String) -> SurrealValue {
    raw.into()
}

#[flutter_rust_bridge::frb(opaque)]
pub struct SurrealProxy {
    surreal: surrealdb::Surreal<Db>,
}

fn parse_resource(resource: String) -> Resource {
    if resource.contains(":") {
        let halves: Vec<&str> = resource.split(":").collect();
        return Resource::RecordId(RecordId::from_table_key(halves[0], halves[1]));
    }
    Resource::Table(resource)
}

pub enum Action {
    Create,
    Update,
    Delete,
}
impl From<SurrealAction> for Action {
    fn from(value: SurrealAction) -> Self {
        match value {
            SurrealAction::Create => Action::Create,
            SurrealAction::Update => Action::Update,
            SurrealAction::Delete => Action::Delete,
            _ => panic!(),
        }
    }
}

pub struct DBNotification {
    pub action: Action,
    pub value: SurrealValue,
    pub uuid: String,
}

impl TryFrom<Notification<Value>> for DBNotification {
    type Error = anyhow::Error;

    fn try_from(value: Notification<Value>) -> std::result::Result<Self, Self::Error> {
        Ok(Self {
            action: value.action.into(),
            uuid: value.query_id.to_string(),
            value: value.data.try_into()?,
        })
    }
}

impl SurrealProxy {
    pub async fn new_mem() -> Result<Self> {
        Ok(SurrealProxy {
            surreal: surrealdb::Surreal::new::<Mem>(())
                .await
                .with_context(|| "Failed to run Surreal::new_mem")?,
        })
    }

    pub async fn new_rocksdb(path: String) -> Result<Self> {
        Ok(SurrealProxy {
            surreal: surrealdb::Surreal::new::<SurrealKv>(path)
                .await
                .with_context(|| "Failed to run Surreal::new_RocksDb")?,
        })
    }

    pub async fn version(&self) -> Result<String> {
        let a = self
            .surreal
            .version()
            .await
            .with_context(|| "Surreal::version")?;
        Ok(format!(
            "{}.{}.{}-{} {}",
            a.major, a.minor, a.patch, a.build, a.pre
        ))
    }

    pub async fn signup(
        &self,
        namespace: String,
        database: String,
        access: String,
        extra: SurrealValue,
    ) -> Result<String> {
        let extra: Value = extra
            .try_into()
            .context("Failed to convert to Surreal Value")?;
        Ok(self
            .surreal
            .signup(Record {
                namespace: &namespace,
                database: &database,
                access: &access,
                params: extra,
            })
            .await
            .with_context(|| "Surreal::signup")?
            .into_insecure_token())
    }

    pub async fn signin(
        &self,
        namespace: String,
        database: String,
        access: String,
        extra: SurrealValue,
    ) -> Result<String> {
        let extra: Value = extra
            .try_into()
            .context("Failed to convert to Surreal Value")?;
        Ok(self
            .surreal
            .signin(Record {
                namespace: &namespace,
                database: &database,
                access: &access,
                params: extra,
            })
            .await
            .with_context(|| "Surreal::signin")?
            .into_insecure_token())
    }

    pub async fn invalidate(&self) -> Result<()> {
        self.surreal
            .invalidate()
            .await
            .with_context(|| "Surreal::invalidate")?;
        Ok(())
    }

    pub async fn authenticate(&self, token: String) -> Result<()> {
        self.surreal
            .authenticate(token)
            .await
            .with_context(|| "Surreal::authenticate")?;
        Ok(())
    }

    pub async fn set(&self, key: String, value: SurrealValue) -> Result<()> {
        let value: Value = value
            .try_into()
            .context("Failed to convert to Surreal Value")?;
        self.surreal
            .set(key, value)
            .await
            .with_context(|| "Surreal::set")?;
        Ok(())
    }

    pub async fn unset(&self, key: String) -> Result<()> {
        self.surreal
            .unset(key)
            .await
            .with_context(|| "Surreal::unset")?;
        Ok(())
    }

    pub async fn use_ns(&self, namespace: String) -> Result<()> {
        self.surreal
            .use_ns(namespace)
            .await
            .with_context(|| "Surreal::unset")?;
        Ok(())
    }

    pub async fn use_db(&self, db: String) -> Result<()> {
        self.surreal
            .use_db(db)
            .await
            .with_context(|| "Surreal::use_db")?;
        Ok(())
    }

    pub async fn select(&self, resource: String) -> Result<SurrealValue> {
        self.surreal
            .select(parse_resource(resource))
            .await
            .with_context(|| "Surreal::select_all")?
            .try_into()
            .context("Failed to convert to Surreal Value")
    }

    pub async fn watch(&self, resource: String, sink: StreamSink<DBNotification>) -> Result<()> {
        let mut stream = self
            .surreal
            .select(parse_resource(resource))
            .live()
            .await
            .with_context(|| "Surreal::select(...).live")?;
        while let Some(result) = stream.next().await {
            sink.add(result.try_into()?)
                .map_err(|a| anyhow::format_err!("Rust to dart Error: {}", a.to_string()))?;
        }
        Ok(())
    }

    pub async fn insert(&self, res: String, data: SurrealValue) -> Result<SurrealValue> {
        let data: Value = data
            .try_into()
            .context("Failed to convert to Surreal Value")?;
        self.surreal
            .insert(parse_resource(res))
            .content(data)
            .await
            .with_context(|| "Surreal::insert(...).content")?
            .try_into()
            .context("Failed to convert to Surreal Value")
    }

    pub async fn upsert(&self, res: String, data: SurrealValue) -> Result<SurrealValue> {
        let data: Value = data
            .try_into()
            .context("Failed to convert to Surreal Value")?;
        self.surreal
            .upsert(parse_resource(res))
            .content(data)
            .await
            .with_context(|| "Surreal::upsert(...).content")?
            .try_into()
            .context("Failed to convert Surreal Value")
    }

    pub async fn create(&self, res: String) -> Result<SurrealValue> {
        self.surreal
            .create(parse_resource(res))
            .await
            .with_context(|| "Surreal::create")?
            .try_into()
            .context("Failed to convert Surreal Value")
    }

    pub async fn update_content(
        &self,
        resource: String,
        data: SurrealValue,
    ) -> Result<SurrealValue> {
        let data: Value = data
            .try_into()
            .context("Failed to convert to Surreal Value")?;
        self.surreal
            .update(parse_resource(resource))
            .content(data)
            .await?
            .try_into()
            .context("Failed to convert Surreal Value")
    }

    pub async fn update_merge(&self, resource: String, data: SurrealValue) -> Result<SurrealValue> {
        let data: Value = data
            .try_into()
            .context("Failed to convert to Surreal Value")?;
        self.surreal
            .update(parse_resource(resource))
            .merge(data)
            .await?
            .try_into()
            .context("Failed to convert Surreal Value")
    }

    pub async fn delete(&self, resource: String) -> Result<()> {
        self.surreal.delete(parse_resource(resource)).await?;
        Ok(())
    }

    pub async fn query(
        &self,
        query: String,
        vars: HashMap<String, SurrealValue>,
    ) -> Result<Vec<SurrealValue>> {
        let mut var: HashMap<String, Value> = HashMap::new();
        for (key, val) in vars {
            var.insert(
                key,
                val.try_into()
                    .context("Failed to convert to Surreal Value")?,
            );
        }
        let mut res = self
            .surreal
            .query(query)
            .bind(var)
            .await
            .with_context(|| "Surreal::query_single")?;
        let mut vec = Vec::with_capacity(res.num_statements());
        for i in 0..res.num_statements() {
            vec.push(
                res.take::<Value>(i)
                    .with_context(|| "Failed taking the result of the Query")?
                    .try_into()
                    .context("Failed to convert Surreal Value")?,
            );
        }
        Ok(vec)
    }

    pub async fn run(&self, function: String, args: SurrealValue) -> Result<SurrealValue> {
        let args: Value = args
            .try_into()
            .context("Failed to convert to Surreal Value")?;
        let ret: Value = self.surreal.run(function).args(args).await?;
        ret.try_into().context("Failed to convert Surreal Value")
    }

    pub async fn export(&self, path: String) -> Result<()> {
        self.surreal.export(path).await?;
        Ok(())
    }

    pub async fn import(&self, path: String) -> Result<()> {
        self.surreal.import(path).await?;
        Ok(())
    }
}

#[flutter_rust_bridge::frb(init)]
pub fn init_app() {
    // Default utilities - feel free to customize
    flutter_rust_bridge::setup_default_user_utils();
}
