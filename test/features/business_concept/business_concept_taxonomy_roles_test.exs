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
    admin_token = get_user_token("app-admin")
    # We get our BC by name
    business_concept = business_concept_by_name(admin_token, bc_name)
    # we should verify that the Bc has been properly retrieved
    {_, http_status_code, %{"data" => business_concept_version}} = business_concept_version_show(admin_token, business_concept["business_concept_version_id"])
    business_concept_version_id = business_concept_version["id"]
    assert rc_ok() == to_response_code(http_status_code)
    assert business_concept_version["name"] == bc_name
    # Now, we should be able to query the taxonomies of a BC
    {_, status_code, json_resp} =
      get_business_concept_taxonomy_roles(token,
      %{business_concept_version_id: business_concept_version_id})
    {:ok, Map.merge(state,
      %{status_code: status_code,  resp: json_resp})}
  end

  defand ~r/^if result "(?<result>[^"]+)" the system will return the user "(?<user_name_role>[^"]+)" with a role "(?<role_name>[^"]+)" in the domain "(?<domain_name>[^"]+)"$/,
    %{result: result, user_name_role: user_name_role, role_name: role_name, domain_name: domain_name}, state do
    assert result == to_response_code(state[:status_code])
    %{"data" => data} = state[:resp]
    collection = data
    assert Enum.member?(Enum.map(collection, &(&1["domain_name"])), domain_name)
    domain_collection_roles = Enum.find(collection, &(&1["domain_name"] == domain_name))["roles"]
    assert Enum.member?(Enum.map(domain_collection_roles, &(&1["principal"]["user_name"])), user_name_role)
    user_roles = Enum.find(domain_collection_roles, &(&1["principal"]["user_name"] == user_name_role))
    assert user_roles["role_name"] == role_name
  end

  defp get_business_concept_taxonomy_roles(token, attrs) do
    headers = get_header(token)
    %HTTPoison.Response{status_code: status_code, body: resp} =
      HTTPoison.get!(business_concept_version_business_concept_version_url(TdBgWeb.Endpoint, :taxonomy_roles, attrs.business_concept_version_id), headers, [])
    {:ok, status_code, resp |> JSON.decode!}
  end
end
