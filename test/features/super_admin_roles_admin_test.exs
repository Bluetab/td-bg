defmodule TdBg.SuperAdminRolesAdminTest do
  use Cabbage.Feature, async: false, file: "super_admin_roles_admin.feature"
  use TdBgWeb.FeatureCase
  import TdBgWeb.Router.Helpers
  import TdBgWeb.ResponseCode
  import TdBgWeb.Taxonomy
  import TdBgWeb.Authentication, only: :functions
  import TdBgWeb.User, only: :functions

  alias TdBgWeb.ApiServices.MockTdAuthService
  alias Poison, as: JSON
  @endpoint TdBgWeb.Endpoint

  setup_all do
    start_supervised MockTdAuthService
    :ok
  end

  #Scenario
  defgiven ~r/^an existing Domain Group called "(?<name>[^"]+)"$/, %{name: name}, state do
    token_admin = build_user_token("app-admin", is_admin: true)
    state = Map.merge(state, %{token_admin: token_admin})
    {_, status_code, _json_resp} = domain_group_create(token_admin,  %{name: name})
    assert rc_created() == to_response_code(status_code)
    {:ok, state}
  end

  defand ~r/^an existing Domain Group called "(?<name>[^"]+)" child of Domain Group "(?<domain_group_name>[^"]+)"$/, %{name: name, domain_group_name: domain_group_name}, state do
    domain_group_info = get_domain_group_by_name(state[:token_admin], domain_group_name)
    {:ok, status_code, json_resp} = domain_group_create(state[:token_admin],  %{name: name, parent_id: domain_group_info["id"]})
    assert rc_created() == to_response_code(status_code)
    assert json_resp["data"]["parent_id"] == domain_group_info["id"]
    {:ok, state}
  end

  defand ~r/^an existing Data Domain called "(?<name>[^"]+)" child of Domain Group "(?<domain_group_name>[^"]+)"$/, %{name: name, domain_group_name: domain_group_name}, state do
    domain_group_info = get_domain_group_by_name(state[:token_admin], domain_group_name)
    {:ok, _status_code, json_resp} = data_domain_create(state[:token_admin],  %{name: name, domain_group_id: domain_group_info["id"]})
    assert json_resp["data"]["domain_group_id"] == domain_group_info["id"]
    {:ok, state}
  end

  defand ~r/^user "app-admin" is logged in the application$/, %{}, state do
    token_admin = build_user_token("app-admin", is_admin: true)
    {:ok, Map.merge(state, %{token: token_admin})}
  end

  defwhen ~r/^"(?<user_name>[^"]+)" grants (?<role_name>[^"]+) role to user "(?<principal_name>[^"]+)" in Domain Group (?<resource_name>[^"]+)$/,
          %{user_name: user_name, role_name: role_name, principal_name: principal_name, resource_name: resource_name}, state do
    domain_group_info = get_domain_group_by_name(state[:token_admin], resource_name)
    user = create_user(principal_name)
    role_info = get_role_by_name(state[:token_admin], role_name)
    acl_entry_params = %{principal_type: "user", principal_id: user.id, resource_type: "domain_group", resource_id: domain_group_info["id"], role_id: role_info["id"]}
    token = get_user_token(user_name)
    {_, status_code, json_resp} = acl_entry_create(token , acl_entry_params)
    {:ok, Map.merge(state, %{status_code: status_code,  resp: json_resp})}
  end

  defthen ~r/^the system returns a result with code "(?<status_code>[^"]+)"$/, %{status_code: status_code}, state do
    assert status_code == to_response_code(state[:status_code])
  end

  defand ~r/^the user "(?<user_name>[^"]+)" has (?<role_name>[^"]+) role in Domain Group "(?<domain_group_name>[^"]+)"$/, %{user_name: user_name, role_name: role_name, domain_group_name: domain_group_name}, state do
    user = create_user(user_name)
    domain_group_info = get_domain_group_by_name(state[:token_admin], domain_group_name)
    {:ok, _status_code, role_data} = user_domain_group_role(state[:token_admin], %{user_id: user.id, domain_group_id: domain_group_info["id"]})
    assert role_data["data"]["name"] == role_name
  end

  defand ~r/^the user "(?<user_name>[^"]+)" has (?<role_name>[^"]+) role in Data Domain "(?<data_domain_name>[^"]+)"$/, %{user_name: user_name, role_name: role_name, data_domain_name: data_domain_name}, state do
    user = create_user(user_name)
    data_domain_info = get_data_domain_by_name(state[:token_admin], data_domain_name)
    {:ok, _status_code, role_data} = user_data_domain_role(state[:token_admin], %{user_id: user.id, data_domain_id: data_domain_info["id"]})
    assert role_data["data"]["name"] == role_name
  end

  #Scenario

  defwhen ~r/^"(?<user_name>[^"]+)" grants (?<role_name>[^"]+) role to user "(?<principal_name>[^"]+)" in Data Domain "(?<resource_name>[^"]+)"$/,
          %{user_name: user_name, role_name: role_name, principal_name: principal_name, resource_name: resource_name}, state do
    data_domain_info = get_data_domain_by_name(state[:token_admin], resource_name)
    user = create_user(principal_name)
    role_info = get_role_by_name(state[:token_admin], role_name)
    acl_entry_params = %{principal_type: "user", principal_id: user.id, resource_type: "data_domain", resource_id: data_domain_info["id"], role_id: role_info["id"]}
    token = get_user_token(user_name)
    {_, status_code, json_resp} = acl_entry_create(token , acl_entry_params)
    {:ok, Map.merge(state, %{status_code: status_code,  resp: json_resp})}
  end

  defp user_domain_group_role(token, attrs) do
    headers = get_header(token)
    %HTTPoison.Response{status_code: status_code, body: resp} =
      HTTPoison.get!(user_domain_group_role_url(@endpoint, :user_domain_group_role, attrs.user_id, attrs.domain_group_id), headers, [])
    {:ok, status_code, resp |> JSON.decode!}
  end

  defp user_data_domain_role(token, attrs) do
    headers = get_header(token)
    %HTTPoison.Response{status_code: status_code, body: resp} =
      HTTPoison.get!(user_data_domain_role_url(@endpoint, :user_data_domain_role, attrs.user_id, attrs.data_domain_id), headers, [])
    {:ok, status_code, resp |> JSON.decode!}
  end

  defp acl_entry_create(token, acl_entry_params) do
    headers = get_header(token)
    body = %{acl_entry: acl_entry_params} |> JSON.encode!
    %HTTPoison.Response{status_code: status_code, body: resp} =
      HTTPoison.post!(acl_entry_url(@endpoint, :create), body, headers, [])
    {:ok, status_code, resp |> JSON.decode!}
  end

end
