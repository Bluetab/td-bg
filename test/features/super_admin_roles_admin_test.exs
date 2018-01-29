defmodule TrueBG.SuperAdminRolesAdminTest do
  use Cabbage.Feature, async: false, file: "super_admin_roles_admin.feature"
  use TrueBGWeb.ConnCase
  import TrueBGWeb.Router.Helpers
  import TrueBGWeb.ResponseCode
  alias Poison, as: JSON
  alias TrueBG.Taxonomies
  alias TrueBG.Accounts
  alias TrueBG.Permissions
  @endpoint TrueBGWeb.Endpoint
  @headers {"Content-type", "application/json"}

  #Scenario
  defgiven ~r/^an existing Domain Group called "(?<name>[^"]+)"$/, %{name: name}, state do
    existing_dg = Taxonomies.get_domain_group_by_name(name)
    {_, _domain_group} =
      if existing_dg == nil do
        Taxonomies.create_domain_group(%{name: name})
      else
        {:ok, existing_dg}
      end
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
    user = Accounts.get_user_by_name(user_name)
    unless user do
      Accounts.create_user(%{user_name: user_name, password: password})
    end
    {:ok, state}
  end

  defand ~r/^user "(?<user_name>[^"]+)" is logged in the application with password "(?<password>[^"]+)"$/, %{user_name: user_name, password: password}, state do
    {_, status_code, json_resp} = session_create(user_name, password)
    assert rc_created() == to_response_code(status_code)
    {:ok, Map.merge(state, %{status_code: status_code, token: json_resp["token"], resp: json_resp})}
  end

  defwhen ~r/^"(?<user_name>[^"]+)" grants (?<role_name>[^"]+) role to user "(?<principal_name>[^"]+)" in Domain Group (?<resource_name>[^"]+)$/,
          %{user_name: _user_name, role_name: role_name, principal_name: principal_name, resource_name: resource_name}, state do
    domain_group_info = Taxonomies.get_domain_group_by_name(resource_name)
    user_info = Accounts.get_user_by_name(principal_name)
    role_info = Permissions.get_role_by_name(role_name)
    acl_entry_params = %{principal_type: "user", principal_id: user_info.id, resource_type: "domain_group", resource_id: domain_group_info.id, role_id: role_info.id}
    {_, status_code, json_resp} = acl_entry_create(state[:token] , acl_entry_params)
    {:ok, Map.merge(state, %{status_code: status_code,  resp: json_resp})}
  end

  defthen ~r/^the system returns a result with code "(?<status_code>[^"]+)"$/, %{status_code: status_code}, state do
    assert status_code == to_response_code(state[:status_code])
  end

  defand ~r/^the user "(?<user_name>[^"]+)" has (?<role_name>[^"]+) role in Domain Group "(?<domain_group_name>[^"]+)"$/, %{user_name: user_name, role_name: role_name, domain_group_name: domain_group_name}, _state do
    user_info = Accounts.get_user_by_name(user_name)
    domain_group_info = Taxonomies.get_domain_group_by_name(domain_group_name)
    role = Permissions.get_role_in_resource(%{user_id: user_info.id, domain_group_id: domain_group_info.id})
    assert role == role_name
  end

  defand ~r/^the user "(?<user_name>[^"]+)" has (?<role_name>[^"]+) role in Data Domain "(?<data_domain_name>[^"]+)"$/, %{user_name: user_name, role_name: role_name, data_domain_name: data_domain_name}, _state do
    user_info = Accounts.get_user_by_name(user_name)
    data_domain_info = Taxonomies.get_data_domain_by_name(data_domain_name)
    role = Permissions.get_role_in_resource(%{user_id: user_info.id, data_domain_id: data_domain_info.id})
    assert role == role_name
  end

  defp session_create(user_name, user_password) do
    body = %{user: %{user_name: user_name, password: user_password}} |> JSON.encode!
    %HTTPoison.Response{status_code: status_code, body: resp} =
      HTTPoison.post!(session_url(@endpoint, :create), body, [@headers], [])
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
