defmodule TdBg.UsersSteps do
  @moduledoc false
  use Cabbage.Feature
  use ExUnit.CaseTemplate

  defgiven ~r/^following users exist with the indicated role in Domain "(?<domain_name>[^"]+)"$/,
           %{domain_name: domain_name, table: table},
           state do
    domain = get_domain_by_name(state[:token_admin], domain_name)

    Enum.each(table, fn %{user: user_name, role: role_name} ->
      %{user_id: user_id} = Authentication.create_claims(user_name: user_name)
      Authentication.create_acl_entry(user_id, "domain", domain["id"], role_name)
    end)
  end
end
