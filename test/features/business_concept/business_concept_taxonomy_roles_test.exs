defmodule TdBg.BusinessConceptTaxonomyTest do
  use Cabbage.Feature, async: false, file: "business_concept/business_concept_taxonomy_roles.feature"
  use TdBgWeb.FeatureCase
  import TdBgWeb.BusinessConcept

  import TdBgWeb.ResponseCode
  import TdBgWeb.User, only: :functions
  import TdBgWeb.Taxonomy, only: :functions
  import TdBgWeb.AclEntry, only: :functions
  import TdBgWeb.Authentication, only: :functions

  alias TdBgWeb.ApiServices.MockTdAuthService
  alias TdBg.BusinessConcepts.BusinessConcept
  alias TdBg.Utils.CollectionUtils

  import_steps TdBg.BusinessConceptSteps
  import_steps TdBg.DomainSteps
  import_steps TdBg.ResultSteps
  import_steps TdBg.UsersSteps

  import TdBg.BusinessConceptSteps
  import TdBg.ResultSteps
  import TdBg.UsersSteps

  setup_all do
    start_supervised MockTdAuthService
    :ok
  end

  setup do
    on_exit fn ->
      MockTdAuthService.set_users([])
    end
  end

  defand ~r/^following users exist in the application:$/, %{table: users}, _state do
    Enum.each(users, &(create_user(&1.user)))
  end

end
