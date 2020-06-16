defmodule TdBg.BusinessConceptHistoryTest do
  use Cabbage.Feature, file: "business_concept/business_concept_history.feature"
  use TdBgWeb.FeatureCase

  import TdBgWeb.BusinessConcept
  import TdBgWeb.ResponseCode
  import TdBgWeb.User, only: :functions
  import TdBgWeb.Taxonomy, only: :functions
  import TdBgWeb.AclEntry, only: :functions
  import TdBgWeb.Authentication, only: :functions

  alias TdBg.Cache.ConceptLoader
  alias TdBg.Cache.DomainLoader
  alias TdBg.Permissions.MockPermissionResolver
  alias TdBg.Search.IndexWorker
  alias TdBgWeb.ApiServices.MockTdAuthService

  import_steps(TdBg.BusinessConceptSteps)
  import_steps(TdBg.DomainSteps)
  import_steps(TdBg.ResultSteps)
  import_steps(TdBg.UsersSteps)

  import TdBg.BusinessConceptSteps
  import TdBg.ResultSteps

  setup_all do
    start_supervised(ConceptLoader)
    start_supervised(DomainLoader)
    start_supervised(IndexWorker)
    start_supervised(MockTdAuthService)
    start_supervised(MockPermissionResolver)
    :ok
  end
end
