defmodule TdBg.UserDomainsTest do
  use Cabbage.Feature, async: false, file: "domains/user_domains.feature"
  use TdBgWeb.FeatureCase

  import TdBgWeb.ResponseCode
  import TdBgWeb.User, only: :functions
  import TdBgWeb.Taxonomy, only: :functions
  import TdBgWeb.AclEntry, only: :functions
  import TdBgWeb.Authentication, only: :functions

  alias TdBgWeb.ApiServices.MockTdAuthService
  alias Poison, as: JSON

  import_steps TdBg.DomainSteps
  import_steps TdBg.ResultSteps
  import_steps TdBg.UsersSteps

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

  defand ~r/^an user "(?<user_name>[^"]+)" that belongs to the group "(?<group_name>[^"]+)"$/,
    %{user_name: user_name, group_name: group_name}, _state do
    create_user(user_name, groups: [%{"name" => group_name}])
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

  defwhen ~r/^user "(?<user_name>[^"]+)" lists the domains where he has a given permission$/, %{user_name: user_name}, _state do
    token = get_user_token(user_name)
    user = get_user_by_name(user_name)
    get_domains_from_user(token, user.id)
  end

  defand ~r/^"(?<group_name>[^"]+)" has a role "(?<role_name>[^"]+)" in Domain "(?<domain_name>[^"]+)"$/, %{group_name: group_name, role_name: role_name, domain_name: domain_name}, state do
    # Your implementation here
    domain_info = get_domain_by_name(state[:token_admin], domain_name)
     %{"id" => group_id} = get_group_by_name(group_name)
    role_info = get_role_by_name(state[:token_admin], role_name)
    acl_entry_params = %{principal_type: "group", principal_id: group_id, resource_type: "domain", resource_id: domain_info["id"], role_id: role_info["id"]}
    {_, status_code, json_resp} = acl_entry_create(state[:token_admin] , acl_entry_params)
    {:ok, Map.merge(state, %{status_code: status_code,  resp: json_resp})}
  end

  defp get_domains_from_user(token, user_id) do
    headers = get_header(token)
    %HTTPoison.Response{status_code: status_code, body: resp} =
      HTTPoison.get!(user_user_url(TdBgWeb.Endpoint, :user_domains, user_id), headers, [])
    {:ok, status_code, resp |> JSON.decode!}
  end

end
