use Mix.Config

# In this file, we keep production configuration that
# you'll likely want to automate and keep away from
# your version control system.
#
# You should document the content of this
# file or create a script for recreating it, since it's
# kept out of version control and might be hard to recover
# or recreate for your teammates (or yourself later on).
config :trueBG, TrueBGWeb.Endpoint,
  secret_key_base: "cY/PweEZ4hdpVM0gjUzWOltZLYeNdrFZK7BQD7/tPYFN9m2GAYhDaCJ4GnueSLNV"

# Configure your database
config :trueBG, TrueBG.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "truebg_prod",
  hostname: "localhost",
  pool_size: 15
