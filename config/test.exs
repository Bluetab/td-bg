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
  username: "postgres",
  password: "postgres",
  database: "td_bg_test",
  hostname: "postgres",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 1

config :td_bg, :api_services_login,
  api_username: "api-admin",
  api_password: "apipass"

config :td_bg, :auth_service,
  api_service: TdBgWeb.ApiServices.MockTdAuthService,
  auth_host: "localhost",
  auth_port: "4001",
  domain: ""

config :td_bg, :dd_service,
  api_service: TdBgWeb.ApiServices.MockTdDdService,
  auth_host: "localhost",
  auth_port: "4005",
  domain: ""

config :td_bg, :elasticsearch,
  search_service: TdBg.Search.MockSearch,
  es_host: "elastic",
  es_port: 9200,
  type_name: "doc"

config :td_bg, :audit_service,
  api_service: TdBgWeb.ApiServices.MockTdAuditService,
  audit_host: "localhost",
  audit_port: "4007",
  audit_domain: ""

config :td_bg, permission_resolver: TdBg.Permissions.MockPermissionResolver

config :td_bg, metrics_publication_frequency: 1000

config :td_cache, redis_host: "redis"
