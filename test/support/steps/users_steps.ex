defmodule TdBg.UsersSteps do
  @moduledoc false
  use Cabbage.Feature
  use ExUnit.CaseTemplate
  import TdBgWeb.Router.Helpers
  import TdBgWeb.Authentication, only: :functions
  alias Poison, as: JSON

  defgiven ~r/^following users exist with the indicated role in Domain Group "(?<domain_group_name>[^"]+)"$/,
    %{domain_group_name: domain_group_name, table: table}, state do

    domain_group = get_domain_group_by_name(state[:token_admin], domain_group_name)
    Enum.map(table, fn(x) ->
        user_name = x[:user]
        role_name = x[:role]
        principal_id = find_or_create_user(user_name).id
        %{"id" => role_id} = get_role_by_name(state[:token_admin], role_name)
        acl_entry_params = %{principal_type: "user", principal_id: principal_id, resource_type: "domain_group", resource_id: domain_group["id"], role_id: role_id}
        {:ok, _, _json_resp} = acl_entry_create(state[:token_admin], acl_entry_params)
        {:ok, _, json_resp} = user_domain_group_role(state[:token_admin], %{user_id: principal_id, domain_group_id: domain_group["id"]})
        assert json_resp["data"]["name"] == role_name
      end)
  end

  defgiven ~r/^following users exist with the indicated role in Data Domain "(?<data_domain_name>[^"]+)"$/,
          %{data_domain_name: data_domain_name, table: table}, %{token_admin: token_admin} = state do

    data_domain = get_data_domain_by_name(token_admin, data_domain_name)
    assert data_domain_name == data_domain["name"]

    create_user_and_acl_entries_fn = fn(x) ->
      user_name = x[:user]
      role_name = x[:role]
      principal_id = create_user(user_name).id
      %{"id" => role_id} = get_role_by_name(token_admin, role_name)
      acl_entry_params = %{principal_type: "user", principal_id: principal_id, resource_type: "data_domain", resource_id: data_domain["id"], role_id: role_id}
      {_, _status_code, _json_resp} = acl_entry_create(token_admin , acl_entry_params)
    end

    users = table |> Enum.map(create_user_and_acl_entries_fn)

    {:ok, Map.merge(state, %{users: users})}
  end

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

  def user_domain_group_role(token, attrs) do
    headers = get_header(token)
    %HTTPoison.Response{status_code: status_code, body: resp} =
      HTTPoison.get!(user_domain_group_role_url(TdBgWeb.Endpoint, :user_domain_group_role, attrs.user_id, attrs.domain_group_id), headers, [])
    {:ok, status_code, resp |> JSON.decode!}
  end

end
