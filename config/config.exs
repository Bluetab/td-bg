# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# Environment
config :td_bg, :env, Mix.env()

# General application configuration
config :td_bg, ecto_repos: [TdBg.Repo]
config :td_bg, TdBg.Repo, pool_size: 5

config :td_bg, index_worker: TdBg.Search.IndexWorker

config :codepagex, :encodings, [
  :ascii,
  ~r[iso8859]i,
  "VENDORS/MICSFT/WINDOWS/CP1252"
]

# Configures the endpoint
config :td_bg, TdBgWeb.Endpoint,
  http: [port: 4002],
  url: [host: "localhost"],
  render_errors: [view: TdBgWeb.ErrorView, accepts: ~w(json)]

# Configures Elixir's Logger
# set EX_LOGGER_FORMAT environment variable to override Elixir's Logger format
# (without the 'end of line' character)
# EX_LOGGER_FORMAT='$date $time [$level] $message'
config :logger, :console,
  format:
    (System.get_env("EX_LOGGER_FORMAT") || "$date\T$time\Z [$level]$levelpad $metadata$message") <>
      "\n",
  level: :info,
  metadata: [:pid, :module],
  utc_log: true

# Configuration for Phoenix
config :phoenix, :json_library, Jason
config :phoenix_swagger, json_library: Jason

config :td_bg, TdBg.Auth.Guardian,
  # optional
  allowed_algos: ["HS512"],
  issuer: "tdauth",
  ttl: {1, :hours},
  secret_key: "SuperSecretTruedat"

config :td_bg, :phoenix_swagger,
  swagger_files: %{
    "priv/static/swagger.json" => [router: TdBgWeb.Router]
  }

config :td_bg, permission_resolver: TdCache.Permissions

config :td_cache, :audit,
  service: "td_bg",
  stream: "audit:events"

config :td_cache, :event_stream,
  consumer_id: "default",
  consumer_group: "bg",
  streams: [
    [key: "business_concept:events", consumer: TdBg.Cache.ConceptLoader],
    [key: "template:events", consumer: TdBg.Search.IndexWorker]
  ]

config :td_bg, TdBg.Scheduler,
  jobs: [
    [
      schedule: "@reboot",
      task: {TdBg.Cache.DomainLoader, :refresh_deleted, []},
      run_strategy: Quantum.RunStrategy.Local
    ],
    [
      schedule: "@reboot",
      task: {TdBg.Cache.DomainLoader, :refresh, [:all, [force: true]]},
      run_strategy: Quantum.RunStrategy.Local
    ],
    [
      schedule: "@daily",
      task: {TdBg.Search.IndexWorker, :reindex, []},
      run_strategy: Quantum.RunStrategy.Local
    ]
  ]

# Import Elasticsearch config
import_config "elastic.exs"

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
