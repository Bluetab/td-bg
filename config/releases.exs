import Config

config :td_bg, TdBg.Repo,
  username: System.fetch_env!("DB_USER"),
  password: System.fetch_env!("DB_PASSWORD"),
  database: System.fetch_env!("DB_NAME"),
  hostname: System.fetch_env!("DB_HOST")

config :td_bg, TdBg.Auth.Guardian, secret_key: System.fetch_env!("GUARDIAN_SECRET_KEY")

config :td_bg, TdBg.Search.Cluster, url: System.fetch_env!("ES_URL")

config :td_bg, :audit_service,
  api_service: TdBgWeb.ApiServices.HttpTdAuditService,
  audit_host: System.fetch_env!("API_AUDIT_HOST"),
  audit_port: System.fetch_env!("API_AUDIT_PORT")

config :td_cache, redis_host: System.fetch_env!("REDIS_HOST")

config :td_cache, :event_stream, consumer_id: System.fetch_env!("HOSTNAME")
