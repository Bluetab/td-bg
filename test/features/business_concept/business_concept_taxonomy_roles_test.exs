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
  alias Poison, as: JSON

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

  defwhen ~r/^user "(?<user_name>[^"]+)" lists taxonomy roles of the business concept "(?<bc_name>[^"]+)"$/,
    %{user_name: user_name, bc_name: bc_name},
    state do
    # First of all we sholud retrieve the token of the user listing the
    # taxonomy roles of the BC in order to check its permissions
    token = get_user_token(user_name)
    # We get our BC by name
    business_concept = business_concept_by_name(token, bc_name)
    # we should verify that the Bc has been properly retrieved
    {_, http_status_code, %{"data" => business_concept}} = business_concept_show(token, business_concept["id"])
    assert rc_ok() == to_response_code(http_status_code)
    assert business_concept["name"] == bc_name
    # Now, we should be able to query the taxonomies of a BC
    {_, status_code,  %{"data" => business_concept_taxonomy_roles}} =
      get_business_concept_taxonomy_roles(token,
      %{business_concept_id: business_concept["id"]})
    {:ok, Map.merge(state,
      %{status_code: status_code,  resp: business_concept_taxonomy_roles})}
  end

  defp get_business_concept_taxonomy_roles(token, attrs) do
    headers = get_header(token)
    %HTTPoison.Response{status_code: status_code, body: resp} =
      HTTPoison.get!(business_concept_business_concept_url(TdBgWeb.Endpoint, :taxonomy_roles, attrs.business_concept_id), headers, [])
    {:ok, status_code, resp |> JSON.decode!}
  end
end
