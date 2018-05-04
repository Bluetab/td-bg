defmodule TdBg.UserGroupsRolesTest do
  use Cabbage.Feature, async: false, file: "roles/users_groups_roles.feature"
  use TdBgWeb.FeatureCase
  import TdBgWeb.Router.Helpers
  import TdBgWeb.ResponseCode
  import TdBgWeb.Taxonomy
  import TdBgWeb.Authentication, only: :functions
  import TdBgWeb.User, only: :functions

  import_steps TdBg.DomainSteps
  import_steps TdBg.ResultSteps
  import_steps TdBg.UsersSteps

  alias TdBgWeb.ApiServices.MockTdAuthService
  alias Poison, as: JSON
  @endpoint TdBgWeb.Endpoint

  import TdBg.ResultSteps
  import TdBgWeb.AclEntry, only: :functions

  setup_all do
    start_supervised MockTdAuthService
    :ok
  end

  defand ~r/^an user "(?<user_name>[^"]+)" that belongs to the group "(?<group_name>[^"]+)"$/,
    %{user_name: user_name, group_name: group_name}, _state do
    create_user(user_name, groups: [%{"name" => group_name}])
  end

  defwhen ~r/^"(?<user_name>[^"]+)" grants (?<role_name>[^"]+) role to group "(?<principal_name>[^"]+)" in Domain (?<resource_name>[^"]+)$/,
          %{user_name: user_name, role_name: role_name, principal_name: principal_name, resource_name: resource_name}, state do
    domain_info = get_domain_by_name(state[:token_admin], resource_name)
    %{"id" => group_id} = get_group_by_name(principal_name)
    role_info = get_role_by_name(state[:token_admin], role_name)
    acl_entry_params = %{principal_type: "group", principal_id: group_id, resource_type: "domain", resource_id: domain_info["id"], role_id: role_info["id"]}
    token = get_user_token(user_name)
    {_, status_code, json_resp} = acl_entry_create(token , acl_entry_params)
    {:ok, Map.merge(state, %{status_code: status_code,  resp: json_resp})}
  end

  defand ~r/^the user "(?<user_name>[^"]+)" has (?<role_name>[^"]+) role in Domain "(?<domain_name>[^"]+)"$/, %{user_name: user_name, role_name: role_name, domain_name: domain_name}, state do
    user = get_user_by_name(user_name)
    domain_info = get_domain_by_name(state[:token_admin], domain_name)
    {:ok, _status_code, json_resp} = user_domain_role(state[:token_admin], %{user_id: user.id, domain_id: domain_info["id"]})
    case json_resp["data"] do
      [] -> assert role_name == "none"
      roles -> assert Enum.member?(Enum.map(roles, &(&1["name"])), role_name)
    end
  end

  defp user_domain_role(token, attrs) do
    headers = get_header(token)
    %HTTPoison.Response{status_code: status_code, body: resp} =
      HTTPoison.get!(user_domain_role_url(@endpoint, :user_domain_role, attrs.user_id, attrs.domain_id), headers, [])
    {:ok, status_code, resp |> JSON.decode!}
  end

end
