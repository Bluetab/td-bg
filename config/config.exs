# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# Environment
config :td_bg, :env, Mix.env()

# General application configuration
config :td_bg,
  ecto_repos: [TdBg.Repo]

# Hashing algorithm
config :td_bg, hashing_module: Comeonin.Bcrypt
config :td_bg, index_worker: TdBg.Search.IndexWorker

config :codepagex, :encodings, [
  :ascii,
  ~r[iso8859]i,
  "VENDORS/MICSFT/WINDOWS/CP1252"
]

# Configures the endpoint
config :td_bg, TdBgWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "tOxTkbz1LLqsEmoRRhSorwFZm35yQbVPP/gdU3cFUYV5IdcoIRNroCeADl4ysBBg",
  render_errors: [view: TdBgWeb.ErrorView, accepts: ~w(json)]

# Configures Elixir's Logger
# set EX_LOGGER_FORMAT environment variable to override Elixir's Logger format
# (without the 'end of line' character)
# EX_LOGGER_FORMAT='$date $time [$level] $message'
config :logger, :console,
  format: (System.get_env("EX_LOGGER_FORMAT") || "$time $metadata[$level] $message") <> "\n",
  metadata: [:request_id]

# Configuration for Phoenix
config :phoenix, :json_library, Jason

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

config :td_bg, :audit_service,
  protocol: "http",
  audits_path: "/api/audits/"

config :td_bg, metrics_publication_frequency: 60_000

config :td_bg, permission_resolver: TdCache.Permissions

config :td_cache, :event_stream,
  consumer_id: "default",
  consumer_group: "bg",
  streams: [
    [key: "business_concept:events", consumer: TdBg.Cache.ConceptLoader]
  ]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
