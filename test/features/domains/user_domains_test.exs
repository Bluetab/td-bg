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

  defwhen ~r/^user "(?<user_name>[^"]+)" lists the domains where he has a given permission$/, %{user_name: user_name}, state do
    token = get_user_token(user_name)
    get_domains_from_user(token)
    {_, status_code, json_resp} = get_domains_from_user(token)
    {:ok, Map.merge(state,
      %{status_code: status_code,  resp: json_resp})}
  end

  defand ~r/^if result "(?<result>[^"]+)" the retrieved list of domains should not be empty$/, %{result: result}, state do
    # Your implementation here
    assert result == to_response_code(state[:status_code])
    %{"data" => data} = state[:resp]
    assert !Enum.empty?(data)
  end

  defand ~r/^the following domains should be in the list:$/, %{table: table}, state do
    %{"data" => data} = state[:resp]
    assert Enum.all?(Enum.map(table, &(&1.domain)),
      fn(x) -> Enum.member?(Enum.map(data, &(&1["domain_name"])), x)
    end)
  end

  defand ~r/^the following domains should not be in the list:$/, %{table: table}, state do
    %{"data" => data} = state[:resp]
    assert Enum.all?(Enum.map(table, &(&1.domain)),
      fn(x) -> !Enum.member?(Enum.map(data, &(&1["domain_name"])), x)
    end)
  end

  defand ~r/^"(?<group_name>[^"]+)" has a role "(?<role_name>[^"]+)" in Domain "(?<domain_name>[^"]+)"$/, %{group_name: group_name, role_name: role_name, domain_name: domain_name}, state do
    # Your implementation here
    domain_info = get_domain_by_name(state[:token_admin], domain_name)
     %{id: group_id} = get_group_by_name(group_name)
    role_info = get_role_by_name(state[:token_admin], role_name)
    acl_entry_params = %{principal_type: "group", principal_id: group_id, resource_type: "domain", resource_id: domain_info["id"], role_id: role_info["id"]}
    {_, status_code, json_resp} = acl_entry_create(state[:token_admin] , acl_entry_params)
    {:ok, Map.merge(state, %{status_code: status_code,  resp: json_resp})}
  end

  defp get_domains_from_user(token) do
    headers = get_header(token)
    %HTTPoison.Response{status_code: status_code, body: resp} =
      HTTPoison.get!(user_url(TdBgWeb.Endpoint, :user_domains), headers, [])
    {:ok, status_code, resp |> JSON.decode!}
  end

end
