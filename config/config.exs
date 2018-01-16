# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :trueBG,
  ecto_repos: [TrueBG.Repo]

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

config :trueBG, TrueBG.Guardian,
  allowed_algos: ["HS512"], # optional
  verify_module: Guardian.JWT,  # optional
  issuer: "TrueBG",
  ttl: { 1, :days },
  verify_issuer: true, # optional
  secret_key: "get-your-own-secret-peeps",
  serializer: TrueBG.GuardianSerializer

# config :guardian, Guardian,
#   issuer: "TrueBG", # Name of your app/company/product
#   secret_key: "zhqD4vVOGLFjDnl6vcTZQUn+nY0MDuEcuHObATsY98W9IuzQyvSeKd9Vr+KlZvts" # Replace this with the output of the mix command

# config :guardian, Guardian,
# issuer: "TrueBG",
# ttl: {30, :days},
# secret_key: "membrillo"

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
