defmodule TdBg.BusinessConceptModificationTest do
  use Cabbage.Feature, file: "business_concept/business_concept_modification.feature"
  use TdBgWeb.FeatureCase
  import TdBgWeb.BusinessConcept

  import TdBgWeb.ResponseCode
  import TdBgWeb.User, only: :functions
  import TdBgWeb.Taxonomy, only: :functions
  import TdBgWeb.AclEntry, only: :functions
  import TdBgWeb.Authentication, only: :functions
  import TdBg.BusinessConceptSteps

  alias TdBgWeb.ApiServices.MockTdAuthService
  alias TdBg.BusinessConcepts.BusinessConcept
  alias TdBg.Utils.CollectionUtils

  import_feature TdBg.BusinessConceptSteps

  setup_all do
    start_supervised MockTdAuthService
    :ok
  end

  setup do
    on_exit fn ->
      rm_business_concept_schema()
    end
  end

end
