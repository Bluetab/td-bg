defmodule TrueBG.SuperAdminRolesAdminTest do
  use Cabbage.Feature, async: false, file: "super_admin_roles_admin.feature"
  use TrueBGWeb.ConnCase
  import TrueBGWeb.Router.Helpers
  import TrueBGWeb.ResponseCode
  import TrueBGWeb.Taxonomy
  import TrueBGWeb.Authentication, only: :functions
  import TrueBGWeb.User, only: :functions
  alias Poison, as: JSON
  alias TrueBG.Taxonomies
  @endpoint TrueBGWeb.Endpoint
  @headers {"Content-type", "application/json"}

  #Scenario
  defgiven ~r/^an existing Domain Group called "(?<name>[^"]+)"$/, %{name: name}, state do
    {_, status_code, json_resp} = session_create("app-admin", "mypass")
    assert rc_created() == to_response_code(status_code)
    state = Map.merge(state, %{status_code: status_code, admin_token: json_resp["token"], resp: json_resp})
    {_, status_code, _json_resp} = domain_group_create(state[:admin_token],  %{name: name})
    assert rc_created() == to_response_code(status_code)
    {:ok, state}
  end

  defand ~r/^an existing Domain Group called "(?<name>[^"]+)" child of Domain Group "(?<domain_group_name>[^"]+)"$/, %{name: name, domain_group_name: domain_group_name}, state do
    domain_group_info = Taxonomies.get_domain_group_by_name(domain_group_name)
    existing_dg = Taxonomies.get_domain_group_by_name(name)
    {_, domain_group} =
      if existing_dg == nil do
        Taxonomies.create_domain_group(%{name: name, parent_id: domain_group_info.id})
      else
        {:ok, existing_dg}
      end
    assert domain_group.parent_id == domain_group_info.id
    {:ok, state}
  end

  defand ~r/^an existing Data Domain called "(?<name>[^"]+)" child of Domain Group "(?<domain_group_name>[^"]+)"$/, %{name: name, domain_group_name: domain_group_name}, state do
    domain_group_info = Taxonomies.get_domain_group_by_name(domain_group_name)
    existing_dd = Taxonomies.get_data_domain_by_name(name)
    {_, data_domain} =
      if existing_dd == nil do
        Taxonomies.create_data_domain(%{name: name, domain_group_id: domain_group_info.id})
      else
        {:ok, existing_dd}
      end
    assert data_domain.domain_group_id == domain_group_info.id
    {:ok, state}
  end

  defand ~r/^an existing user "(?<user_name>[^"]+)" with password "(?<password>[^"]+)" without "super-admin" permission$/, %{user_name: user_name, password: password}, state do
    user = get_user_by_name(state[:admin_token], user_name)
    unless user do
      user_create(state[:admin_token], %{user_name: user_name, password: password})
    end
    {:ok, state}
  end

  defand ~r/^user "(?<user_name>[^"]+)" is logged in the application with password "(?<password>[^"]+)"$/, %{user_name: user_name, password: password}, state do
    {_, status_code, json_resp} = session_create(user_name, password)
    assert rc_created() == to_response_code(status_code)
    {:ok, Map.merge(state, %{status_code: status_code, token: json_resp["token"], resp: json_resp})}
  end

  defand ~r/^user "app-admin" is logged in the application$/, %{}, state do
    {_, status_code, json_resp} = session_create("app-admin", "mypass")
    assert rc_created() == to_response_code(status_code)
    {:ok, Map.merge(state, %{status_code: status_code, token: json_resp["token"], resp: json_resp})}
  end

  defwhen ~r/^"(?<user_name>[^"]+)" grants (?<role_name>[^"]+) role to user "(?<principal_name>[^"]+)" in Domain Group (?<resource_name>[^"]+)$/,
          %{user_name: _user_name, role_name: role_name, principal_name: principal_name, resource_name: resource_name}, state do
    domain_group_info = Taxonomies.get_domain_group_by_name(resource_name)
    user_info = get_user_by_name(state[:admin_token], principal_name)
    role_info = get_role_by_name(state[:admin_token], role_name)
    acl_entry_params = %{principal_type: "user", principal_id: user_info["id"], resource_type: "domain_group", resource_id: domain_group_info.id, role_id: role_info["id"]}
    {_, status_code, json_resp} = acl_entry_create(state[:token] , acl_entry_params)
    {:ok, Map.merge(state, %{status_code: status_code,  resp: json_resp})}
  end

  defthen ~r/^the system returns a result with code "(?<status_code>[^"]+)"$/, %{status_code: status_code}, state do
    assert status_code == to_response_code(state[:status_code])
  end

  defand ~r/^the user "(?<user_name>[^"]+)" has (?<role_name>[^"]+) role in Domain Group "(?<domain_group_name>[^"]+)"$/, %{user_name: user_name, role_name: role_name, domain_group_name: domain_group_name}, state do
    user_info = get_user_by_name(state[:admin_token], user_name)
    domain_group_info = Taxonomies.get_domain_group_by_name(domain_group_name)
    {:ok, _status_code, role_data} = user_domain_group_role(state[:admin_token], %{user_id: user_info["id"], domain_group_id: domain_group_info.id})
    assert role_data["data"]["name"] == role_name
  end

  defand ~r/^the user "(?<user_name>[^"]+)" has (?<role_name>[^"]+) role in Data Domain "(?<data_domain_name>[^"]+)"$/, %{user_name: user_name, role_name: role_name, data_domain_name: data_domain_name}, state do
    user_info = get_user_by_name(state[:admin_token], user_name)
    data_domain_info = Taxonomies.get_data_domain_by_name(data_domain_name)
    #role = Permissions.get_role_in_resource(%{user_id: user_info["id"], data_domain_id: data_domain_info.id})
    {:ok, _status_code, role_data} = user_data_domain_role(state[:admin_token], %{user_id: user_info["id"], data_domain_id: data_domain_info.id})
    assert role_data["data"]["name"] == role_name
  end

  #Scenario

  defwhen ~r/^"(?<user_name>[^"]+)" grants (?<role_name>[^"]+) role to user "(?<principal_name>[^"]+)" in Data Domain "(?<resource_name>[^"]+)"$/,
          %{user_name: _user_name, role_name: role_name, principal_name: principal_name, resource_name: resource_name}, state do
    data_domain_info = Taxonomies.get_data_domain_by_name(resource_name)
    user_info = get_user_by_name(state[:admin_token], principal_name)
    role_info = get_role_by_name(state[:admin_token], role_name)
    acl_entry_params = %{principal_type: "user", principal_id: user_info["id"], resource_type: "data_domain", resource_id: data_domain_info.id, role_id: role_info["id"]}
    {_, status_code, json_resp} = acl_entry_create(state[:token] , acl_entry_params)
    {:ok, Map.merge(state, %{status_code: status_code,  resp: json_resp})}
  end

  defp user_domain_group_role(token, attrs) do
    headers = [@headers, {"authorization", "Bearer #{token}"}]
    %HTTPoison.Response{status_code: status_code, body: resp} =
      HTTPoison.get!(user_domain_group_role_url(@endpoint, :user_domain_group_role, attrs.user_id, attrs.domain_group_id), headers, [])
    {:ok, status_code, resp |> JSON.decode!}
  end

  defp user_data_domain_role(token, attrs) do
    headers = [@headers, {"authorization", "Bearer #{token}"}]
    %HTTPoison.Response{status_code: status_code, body: resp} =
      HTTPoison.get!(user_data_domain_role_url(@endpoint, :user_data_domain_role, attrs.user_id, attrs.data_domain_id), headers, [])
    {:ok, status_code, resp |> JSON.decode!}
  end

  defp acl_entry_create(token, acl_entry_params) do
    headers = [@headers, {"authorization", "Bearer #{token}"}]
    body = %{acl_entry: acl_entry_params} |> JSON.encode!
    %HTTPoison.Response{status_code: status_code, body: resp} =
      HTTPoison.post!(acl_entry_url(@endpoint, :create), body, headers, [])
    {:ok, status_code, resp |> JSON.decode!}
  end
end
