# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# Environment
config :td_bg, :env, Mix.env()

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
  render_errors: [view: TdBgWeb.ErrorView, accepts: ~w(json)]

# Configures Elixir's Logger
# set EX_LOGGER_FORMAT environment variable to override Elixir's Logger format
# (without the 'end of line' character)
# EX_LOGGER_FORMAT='$date $time [$level] $message'
config :logger, :console,
  format: (System.get_env("EX_LOGGER_FORMAT") || "$time $metadata[$level] $message") <> "\n",
  metadata: [:request_id]

# Configuration for Phoenix
config :phoenix, :json_library, Jason

config :td_bg, TdBg.Auth.Guardian,
  # optional
  allowed_algos: ["HS512"],
  issuer: "tdauth",
  ttl: {1, :hours},
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

config :td_bg, metrics_publication_frequency: 60_000

config :td_bg, permission_resolver: TdCache.Permissions

config :td_cache,
  permissions: [
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
    :__manage_business_concept_alias,
    :view_data_structure,
    :view_draft_business_concepts,
    :view_approval_pending_business_concepts,
    :view_published_business_concepts,
    :view_versioned_business_concepts,
    :view_rejected_business_concepts,
    :view_deprecated_business_concepts,
    :manage_business_concept_links,
    :manage_quality_rule,
    :manage_confidential_business_concepts,
    :create_ingest,
    :update_ingest,
    :send_ingest_for_approval,
    :delete_ingest,
    :publish_ingest,
    :reject_ingest,
    :deprecate_ingest,
    :view_draft_ingests,
    :view_approval_pending_ingests,
    :view_published_ingests,
    :view_versioned_ingests,
    :view_rejected_ingests,
    :view_deprecated_ingests,
    :manage_confidential_structures,
    :manage_ingest_relations,
    :view_data_structures_profile
  ]

config :td_cache, :event_stream,
  consumer_id: "default",
  consumer_group: "bg",
  streams: [
    [key: "business_concept:events", consumer: TdBg.Cache.ConceptLoader]
  ]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
