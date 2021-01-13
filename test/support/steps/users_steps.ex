defmodule TdBg.UsersSteps do
  @moduledoc false
  use Cabbage.Feature
  use ExUnit.CaseTemplate

  defgiven ~r/^following users exist with the indicated role in Domain "(?<domain_name>[^"]+)"$/,
           %{domain_name: domain_name, table: table},
           state do
    domain = get_domain_by_name(state[:token_admin], domain_name)

    Enum.map(table, fn row ->
      user_name = row[:user]
      role_name = row[:role]
      %{user_id: user_id} = create_session(user_name)
      %{id: role_id} = get_role_by_name(role_name)

      acl_entry_params = %{
        principal_type: "user",
        principal_id: user_id,
        resource_type: "domain",
        resource_id: domain["id"],
        role_id: role_id,
        role_name: role_name
      }

      {:ok, _, _json_resp} = acl_entry_create(acl_entry_params)
    end)
  end
end
