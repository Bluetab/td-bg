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
  username: "${DB_USER}",
  password: "${DB_PASSWORD}",
  database: "${DB_NAME}",
  hostname: "${DB_HOST}",
  pool_size: 10

config :td_bg, TdBg.Auth.Guardian,
  # optional
  allowed_algos: ["HS512"],
  issuer: "tdauth",
  ttl: {1, :hours},
  secret_key: "${GUARDIAN_SECRET_KEY}"

config :td_bg, TdBg.Search.Cluster,
  url: "${ES_URL}"

config :td_bg, :audit_service,
  api_service: TdBgWeb.ApiServices.HttpTdAuditService,
  audit_host: "${API_AUDIT_HOST}",
  audit_port: "${API_AUDIT_PORT}",
  audit_domain: ""

config :td_cache, redis_host: "${REDIS_HOST}"

config :td_cache, :event_stream,
  consumer_id: "${HOSTNAME}",
  consumer_group: "bg",
  streams: [
    [key: "business_concept:events", consumer: TdBg.Cache.ConceptLoader],
    [key: "template:events", consumer: TdBg.Search.IndexWorker]
  ]
