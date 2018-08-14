# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :td_bg,
  ecto_repos: [TdBg.Repo]

# Hashing algorithm
config :td_bg, hashing_module: Comeonin.Bcrypt

config :codepagex, :encodings, [
  :ascii,
  ~r[iso8859]i,
  "VENDORS/MICSFT/WINDOWS/CP1252"
]

# Configures the endpoint
config :td_bg, TdBgWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "tOxTkbz1LLqsEmoRRhSorwFZm35yQbVPP/gdU3cFUYV5IdcoIRNroCeADl4ysBBg",
  render_errors: [view: TdBgWeb.ErrorView, accepts: ~w(json)],
  pubsub: [name: TdBg.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :td_bg, TdBg.Auth.Guardian,
  allowed_algos: ["HS512"], # optional
  issuer: "tdauth",
  ttl: { 1, :hours },
  secret_key: "SuperSecretTruedat"

config :td_bg, :auth_service,
  protocol: "http",
  users_path: "/api/users/",
  sessions_path: "/api/sessions/",
  groups_path: "/api/groups"

config :td_bg, :dd_service,
  protocol: "http",
  data_structures_path: "/api/data_structures",
  data_fields_path: "/api/data_fields",
  groups_path: "/api/groups"

config :td_bg, :phoenix_swagger,
       swagger_files: %{
         "priv/static/swagger.json" => [router: TdBgWeb.Router]
       }

config :td_bg, :audit_service,
        protocol: "http",
        audits_path: "/api/audits/"

config :td_bg, cache_domains_on_startup: true
config :td_bg, cache_busines_concepts_on_startup: true
config :td_bg, metrics_busines_concepts_on_startup: true

config :td_bg, permission_resolver: TdPerms.Permissions

# config :grafana,
#   api_host: "http://localhost:3000",
#   api_key: "Bearer eyJrIjoieTRlVWZpZmhZQmRidE56YUV5eDdBaDRoMTRyclcyYXYiLCJuIjoiYWRzZnNhIiwiaWQiOjF9",
#   datasource: "grafana_pro",
#   grafana_json: "static/dashboard_panel.json"
# config :grafana,
#   api_host: "http://grafana.truedat.io",
#   api_key: "Bearer eyJrIjoiUXh5UWxPSjMxNDBkYXJuZ3oxUlVDZGNVR3Y3YkZlcnMiLCJuIjoidXNlcjEiLCJpZCI6MX0=",
#   datasource: "Prometheus",
#   grafana_json: "static/dashboard_panel.json"

config :td_perms, permissions: [
  :is_admin,
  :create_acl_entry,
  :update_acl_entry,
  :delete_acl_entry,
  :create_domain,
  :update_domain,
  :delete_domain,
  :view_domain,
  :create_business_concept,
  :create_data_structure,
  :update_business_concept,
  :update_data_structure,
  :send_business_concept_for_approval,
  :delete_business_concept,
  :delete_data_structure,
  :publish_business_concept,
  :reject_business_concept,
  :deprecate_business_concept,
  :manage_business_concept_alias,
  :view_data_structure,
  :view_draft_business_concepts,
  :view_approval_pending_business_concepts,
  :view_published_business_concepts,
  :view_versioned_business_concepts,
  :view_rejected_business_concepts,
  :view_deprecated_business_concepts,
  :create_business_concept_link,
  :delete_business_concept_link,
  :create_quality_rule
]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
