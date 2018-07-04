defmodule TdBg.UsersSteps do
  @moduledoc false
  use Cabbage.Feature
  use ExUnit.CaseTemplate

  defgiven ~r/^following users exist with the indicated role in Domain "(?<domain_name>[^"]+)"$/,
    %{domain_name: domain_name, table: table}, state do

    domain = get_domain_by_name(state[:token_admin], domain_name)
    Enum.map(table, fn(x) ->
        user_name = x[:user]
        role_name = x[:role]
        principal_id = find_or_create_user(user_name).id
        %{id: role_id} = get_role_by_name(role_name)
        acl_entry_params = %{principal_type: "user", principal_id: principal_id, resource_type: "domain", resource_id: domain["id"], role_id: role_id, role_name: role_name}
        {:ok, _, _json_resp} = acl_entry_create(state[:token_admin], acl_entry_params)
      end)
  end

  defwhen ~r/^"(?<user_name>[^"]+)" grants (?<role_name>[^"]+) role to user "(?<principal_name>[^"]+)" in Domain "(?<resource_name>[^"]+)"$/,
          %{user_name: user_name, role_name: role_name, principal_name: principal_name, resource_name: resource_name}, state do
    domain_info = get_domain_by_name(state[:token_admin], resource_name)
    user = create_user(principal_name)
    role_info = get_role_by_name(role_name)
    acl_entry_params = %{principal_type: "user", principal_id: user.id, resource_type: "domain", resource_id: domain_info["id"], role_id: role_info["id"]}
    token = get_user_token(user_name)
    {_, status_code, json_resp} = acl_entry_create(token , acl_entry_params)
    {:ok, Map.merge(state, %{status_code: status_code,  resp: json_resp})}
  end

end
