use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :td_bg, TdBgWeb.Endpoint,
  http: [port: 3001],
  server: true

# Hashing algorithm just for testing porpouses
config :td_bg, hashing_module: TdBg.DummyHashing

# Print only warnings and errors during test
config :logger, level: :warn

# Configure your database
config :td_bg, TdBg.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "td_bg_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 1

config :td_bg,
  # business concept content  schema location
  bc_schema_location: "bc_schema.test"

config :td_bg, :api_services_login,
  user_name: "api-admin",
  password: "apipass"

config :td_bg, :auth_service, api_service: TdBgWeb.ApiServices.MockTdAuthService,
  host: "localhost",
  port: "4001",
  domain: ""