# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
import Config

config :td_bg, Oban,
  prefix: "private",
  plugins: [
    {Oban.Plugins.Pruner, max_age: 24 * 60 * 60},
    {Oban.Plugins.Cron,
     crontab: [
       {"0 */3 * * *", TdBg.BusinessConcepts.BusinessConceptVersions.Workers.OutdatedEmbeddings},
       {"@hourly", TdBg.BusinessConcepts.BusinessConceptVersions.Workers.EmbeddingsDeletion}
     ]}
  ],
  engine: Oban.Engines.Basic,
  notifier: Oban.Notifiers.Postgres,
  queues: [default: 5, embedding_upserts: 10, embedding_deletion: 5],
  repo: TdBg.Repo

# Environment
config :td_bg, :env, Mix.env()
config :td_cluster, :env, Mix.env()
config :td_cluster, groups: [:bg]
config :td_core, :env, Mix.env()

# General application configuration
config :td_bg, ecto_repos: [TdBg.Repo]
config :td_bg, TdBg.Repo, pool_size: 5

config :td_cache, :lang, "en"

config :td_bg, TdBg.BusinessConcepts.BulkUploader, timeout: 600
config :td_bg, TdBg.BusinessConcepts.BulkUploader, uploads_tmp_folder: "/tmp"

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
    (System.get_env("EX_LOGGER_FORMAT") || "$date\T$time\Z [$level] $metadata$message") <>
      "\n",
  level: :info,
  metadata: [:pid, :module],
  utc_log: true

# Configuration for Phoenix
config :phoenix, :json_library, Jason

config :td_bg, TdBg.Auth.Guardian,
  allowed_algos: ["HS512"],
  issuer: "tdauth",
  ttl: {1, :hours},
  secret_key: "SuperSecretTruedat"

config :td_cache, :audit,
  service: "td_bg",
  stream: "audit:events"

config :td_cache, :event_stream,
  consumer_id: "default",
  consumer_group: "bg",
  streams: [
    [key: "business_concept:events", consumer: TdBg.Cache.ConceptLoader],
    [key: "template:events", consumer: TdCore.Search.IndexWorker]
  ]

config :td_bg, TdBg.Scheduler,
  jobs: [
    [
      schedule: "@reboot",
      task: {TdBg.Jobs.UpdateDomainFields, :run, []},
      run_strategy: Quantum.RunStrategy.Local
    ],
    [
      schedule: "@reboot",
      task: {TdBg.Jobs.UploadTmpFilesCleaner, :run, []},
      run_strategy: Quantum.RunStrategy.Local
    ],
    [
      schedule: "@reboot",
      task: {TdCache.CacheCleaner, :clean, [["domains:root", "domains:id_to_parent_ids"]]},
      run_strategy: Quantum.RunStrategy.Local
    ],
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
      task: {TdCore.Search.IndexWorker, :reindex, [:concepts, :all]},
      run_strategy: Quantum.RunStrategy.Local
    ]
  ]

config :td_bg, :limit_outdated_embeddings, 50_000

# Import Elasticsearch config
import_config "elastic.exs"

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
