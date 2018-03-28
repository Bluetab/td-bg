use Mix.Config

# In this file, we keep production configuration that
# you'll likely want to automate and keep away from
# your version control system.
#
# You should document the content of this
# file or create a script for recreating it, since it's
# kept out of version control and might be hard to recover
# or recreate for your teammates (or yourself later on).
config :td_bg, TdBgWeb.Endpoint,
  secret_key_base: "cY/PweEZ4hdpVM0gjUzWOltZLYeNdrFZK7BQD7/tPYFN9m2GAYhDaCJ4GnueSLNV"

# Configure your database
config :td_bg, TdBg.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "td_bg_prod",
  hostname: "localhost",
  pool_size: 10

config :td_bg, TdBg.Auth.Guardian,
  allowed_algos: ["HS512"], # optional
  issuer: "tdauth",
  ttl: { 1, :hours },
  secret_key: "SuperSecretTruedat"

config :td_bg, :api_services_login,
  api_username: "api-admin",
  api_password: "xxxxx"

config :td_bg, :auth_service, api_service: TdBgWeb.ApiServices.HttpTdAuthService,
  auth_host: "localhost",
  auth_port: "4001",
  auth_domain: ""

config :td_bg, :elasticsearch,
  search_service: TdBg.Search,
  es_host: "localhost",
  es_port: 9200,
  type_name: "doc"
