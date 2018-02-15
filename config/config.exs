# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :trueBG,
  ecto_repos: [TrueBG.Repo]

# Hashing algorithm
config :trueBG, hashing_module: Comeonin.Bcrypt

# Configures the endpoint
config :trueBG, TrueBGWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "tOxTkbz1LLqsEmoRRhSorwFZm35yQbVPP/gdU3cFUYV5IdcoIRNroCeADl4ysBBg",
  render_errors: [view: TrueBGWeb.ErrorView, accepts: ~w(json)],
  pubsub: [name: TrueBG.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :trueBG, TrueBG.Auth.Guardian,
  allowed_algos: ["HS512"], # optional
  issuer: "trueBG",
  ttl: { 1, :hours },
  secret_key: "SuperSecretTruedat"

config :canary, repo: TrueBG.Repo,
  unauthorized_handler: {TrueBG.Auth.Canary, :handle_unauthorized},
  not_found_handler: {TrueBG.Auth.Canary, :handle_not_found}

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
