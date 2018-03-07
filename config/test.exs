use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :td_bg, TdBGWeb.Endpoint,
  http: [port: 4001],
  server: true

# Hashing algorithm just for testing porpouses
config :td_bg, hashing_module: TdBG.DummyHashing

# Print only warnings and errors during test
config :logger, level: :warn

# Configure your database
config :td_bg, TdBG.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "TdBG_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 1

config :td_bg,
  # business concept content  schema location
  bc_schema_location: "bc_schema.test"
