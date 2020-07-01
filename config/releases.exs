import Config

config :td_bg, TdBg.Repo,
  username: System.fetch_env!("DB_USER"),
  password: System.fetch_env!("DB_PASSWORD"),
  database: System.fetch_env!("DB_NAME"),
  hostname: System.fetch_env!("DB_HOST"),
  pool_size: System.get_env("DB_POOL_SIZE", "5") |> String.to_integer()

config :td_bg, TdBg.Auth.Guardian, secret_key: System.fetch_env!("GUARDIAN_SECRET_KEY")

config :td_bg, TdBg.Search.Cluster, url: System.fetch_env!("ES_URL")

config :td_cache,
  redis_host: System.fetch_env!("REDIS_HOST"),
  port: System.get_env("REDIS_PORT", "6379") |> String.to_integer()

config :td_cache, :event_stream, consumer_id: System.fetch_env!("HOSTNAME")
