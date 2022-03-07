import Config

config :td_bg, TdBg.Repo,
  username: System.fetch_env!("DB_USER"),
  password: System.fetch_env!("DB_PASSWORD"),
  database: System.fetch_env!("DB_NAME"),
  hostname: System.fetch_env!("DB_HOST"),
  port: System.get_env("DB_PORT", "5432") |> String.to_integer(),
  pool_size: System.get_env("DB_POOL_SIZE", "5") |> String.to_integer()

config :td_bg, TdBg.Auth.Guardian, secret_key: System.fetch_env!("GUARDIAN_SECRET_KEY")

config :td_cache,
  redis_host: System.fetch_env!("REDIS_HOST"),
  port: System.get_env("REDIS_PORT", "6379") |> String.to_integer(),
  password: System.get_env("REDIS_PASSWORD")

config :td_cache, :event_stream, consumer_id: System.fetch_env!("HOSTNAME")

config :td_bg, TdBg.Scheduler,
  jobs: [
    [
      schedule: "@reboot",
      task: {TdCache.CacheCleaner, :clean, ["domains:root", "domains:id_to_parent_ids"]},
      run_strategy: Quantum.RunStrategy.Local
    ],
    [
      schedule: "@reboot",
      task: {TdBg.Cache.DomainLoader, :refresh_deleted, []},
      run_strategy: Quantum.RunStrategy.Local
    ],
    [
      schedule: "@reboot",
      task: {TdBg.Cache.DomainLoader, :refresh, [:all, [force: true, publish: false]]},
      run_strategy: Quantum.RunStrategy.Local
    ],
    [
      schedule: System.get_env("ES_REFRESH_SCHEDULE", "@daily"),
      task: {TdBg.Search.IndexWorker, :reindex, []},
      run_strategy: Quantum.RunStrategy.Local
    ]
  ]

config :td_bg, TdBg.Search.Cluster, url: System.fetch_env!("ES_URL")

with username when not is_nil(username) <- System.get_env("ES_USERNAME"),
     password when not is_nil(password) <- System.get_env("ES_PASSWORD") do
  config :td_bg, TdBg.Search.Cluster,
    username: username,
    password: password
end
