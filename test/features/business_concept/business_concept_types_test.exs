defmodule TdBg.BusinessConceptTypesTest do
  use Cabbage.Feature, file: "business_concept/business_concept_types.feature"
  use TdBgWeb.FeatureCase
  import TdBgWeb.BusinessConcept

  import TdBgWeb.ResponseCode
  import TdBgWeb.Taxonomy, only: :functions
  import TdBgWeb.Authentication, only: :functions
  import TdBg.BusinessConceptSteps

  alias TdBg.BusinessConcepts.BusinessConcept
  alias TdBg.Utils.CollectionUtils
  alias TdBgWeb.ApiServices.MockTdAuditService
alias TdBgWeb.ApiServices.MockTdAuthService

  import_feature(TdBg.BusinessConceptSteps)
  import_steps(TdBg.ResultSteps)

  import TdBg.BusinessConceptSteps
  import TdBg.ResultSteps

  setup_all do
    start_supervised(MockTdAuthService)
    start_supervised(MockTdAuditService)
    :ok
  end

  setup do
    on_exit(fn ->
      rm_business_concept_schema()
    end)
  end
end
