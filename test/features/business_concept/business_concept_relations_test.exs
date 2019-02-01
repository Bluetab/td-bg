defmodule TdBg.BusinessConceptRelationsTest do
  use Cabbage.Feature, file: "business_concept/business_concept_relations.feature"
  use TdBgWeb.FeatureCase
  import TdBgWeb.BusinessConcept

  import TdBgWeb.ResponseCode
  import TdBgWeb.Taxonomy, only: :functions
  import TdBgWeb.Authentication, only: :functions

  alias TdBg.BusinessConcepts.BusinessConcept
  alias TdBg.Permissions.MockPermissionResolver
  alias TdBg.Utils.CollectionUtils
  alias TdBgWeb.ApiServices.MockTdAuditService
  alias TdBgWeb.ApiServices.MockTdAuthService

  import_steps(TdBg.BusinessConceptSteps)
  import_steps(TdBg.DomainSteps)
  import_steps(TdBg.ResultSteps)

  import TdBg.BusinessConceptSteps
  import TdBg.ResultSteps

  @df_cache Application.get_env(:td_bg, :df_cache)

  setup_all do
    start_supervised(MockTdAuthService)
    start_supervised(MockTdAuditService)
    start_supervised(MockPermissionResolver)
    start_supervised(@df_cache)
    :ok
  end
end
