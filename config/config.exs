# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :td_bg,
  ecto_repos: [TdBg.Repo]

# Hashing algorithm
config :td_bg, hashing_module: Comeonin.Bcrypt

# Configures the endpoint
config :td_bg, TdBgWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "tOxTkbz1LLqsEmoRRhSorwFZm35yQbVPP/gdU3cFUYV5IdcoIRNroCeADl4ysBBg",
  render_errors: [view: TdBgWeb.ErrorView, accepts: ~w(json)],
  pubsub: [name: TdBg.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :td_bg, TdBg.Auth.Guardian,
  allowed_algos: ["HS512"], # optional
  issuer: "tdauth",
  ttl: { 1, :hours },
  secret_key: "SuperSecretTruedat"

config :td_bg, :auth_service,
  protocol: "http",
  users_path: "/api/users/",
  sessions_path: "/api/sessions/",
  groups_path: "/api/groups"

config :td_bg, :dd_service,
  protocol: "http",
  data_structures_path: "/api/data_structures",
  groups_path: "/api/groups"

config :td_bg, :phoenix_swagger,
       swagger_files: %{
         "priv/static/swagger.json" => [router: TdBgWeb.Router]
       }

config :td_bg, :audit_service,
        protocol: "http",
        audits_path: "/api/audits/"

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
