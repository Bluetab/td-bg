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
  username: "${DB_USER}",
  password: "${DB_PASSWORD}",
  database: "${DB_NAME}",
  hostname: "${DB_HOST}",
  pool_size: 10

config :td_bg, TdBg.Auth.Guardian,
  allowed_algos: ["HS512"], # optional
  issuer: "tdauth",
  ttl: { 1, :hours },
  secret_key: "${GUARDIAN_SECRET_KEY}"

config :td_bg, :api_services_login,
  api_username: "${API_USER}",
  api_password: "${API_PASSWORD}"

config :td_bg, :auth_service, api_service: TdBgWeb.ApiServices.HttpTdAuthService,
  auth_host: "${API_AUTH_HOST}",
  auth_port: "${API_AUTH_PORT}",
  auth_domain: ""

config :td_bg, :dd_service, api_service: TdBgWeb.ApiServices.HttpTdDdService,
  dd_host: "${API_DD_HOST}",
  dd_port: "${API_DD_PORT}",
  dd_domain: ""

config :td_bg, :elasticsearch,
  search_service: TdBg.Search,
  es_host: "${ES_HOST}",
  es_port: "${ES_PORT}",
  type_name: "doc"

config :td_bg, :audit_service, api_service: TdBgWeb.ApiServices.HttpTdAuditService,
  audit_host: "${API_AUDIT_HOST}",
  audit_port: "${API_AUDIT_PORT}",
  audit_domain: ""
