use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :trueBG, TrueBGWeb.Endpoint,
  http: [port: 4001],
  server: true

# Print only warnings and errors during test
config :logger, level: :warn

# Configure your database
config :trueBG, TrueBG.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: System.get_env("DATABASE_PASSWD") || "postgres",
  database: "truebg_test",
  hostname: System.get_env("DATABASE_HOST") || "localhost",
  pool: Ecto.Adapters.SQL.Sandbox
