defmodule TdBg.SuperAdminRolesAdminTest do
  use Cabbage.Feature, async: false, file: "roles/super_admin_roles_admin.feature"
  use TdBgWeb.FeatureCase
  import TdBgWeb.AclEntry
  import TdBgWeb.Authentication, only: :functions
  import TdBgWeb.ResponseCode
  import TdBgWeb.Taxonomy
  import TdBgWeb.User, only: :functions

  import_steps(TdBg.DomainSteps)
  import_steps(TdBg.ResultSteps)
  import_steps(TdBg.UsersSteps)

  alias TdBgWeb.ApiServices.MockTdAuthService

  import TdBg.ResultSteps

  setup_all do
    start_supervised(MockTdAuthService)
    :ok
  end

  defand ~r/^user "app-admin" is logged in the application$/, %{}, state do
    token_admin = build_user_token("app-admin", is_admin: true)
    {:ok, Map.merge(state, %{token: token_admin})}
  end

  defwhen ~r/^"(?<user_name>[^"]+)" grants (?<role_name>[^"]+) role to user "(?<principal_name>[^"]+)" in Domain (?<resource_name>[^"]+)$/,
          %{
            user_name: user_name,
            role_name: role_name,
            principal_name: principal_name,
            resource_name: resource_name
          },
          state do
    domain_info = get_domain_by_name(state[:token_admin], resource_name)
    user = create_user(principal_name)
    role_info = get_role_by_name(state[:token_admin], role_name)

    acl_entry_params = %{
      principal_type: "user",
      principal_id: user.id,
      resource_type: "domain",
      resource_id: domain_info["id"],
      role_id: role_info["id"]
    }

    token = get_user_token(user_name)
    {_, status_code, json_resp} = acl_entry_create(token, acl_entry_params)
    {:ok, Map.merge(state, %{status_code: status_code, resp: json_resp})}
  end

#  defand ~r/^the user "(?<user_name>[^"]+)" has (?<role_name>[^"]+) role in Domain "(?<domain_name>[^"]+)"$/,
#         %{user_name: user_name, role_name: role_name, domain_name: domain_name},
#         state do
#    user = create_user(user_name)
#    domain_info = get_domain_by_name(state[:token_admin], domain_name)
#
#    {:ok, _status_code, json_resp} =
#      user_domain_role(state[:token_admin], %{user_id: user.id, domain_id: domain_info["id"]})
#
#    # assert Enum.member?(Enum.map(json_resp["data"], &(if &1["name"], do: &1["name"], else: "none")), role_name)
#    case json_resp["data"] do
#      [] -> assert role_name == "none"
#      roles -> assert Enum.member?(Enum.map(roles, & &1["name"]), role_name)
#    end
#  end

end
