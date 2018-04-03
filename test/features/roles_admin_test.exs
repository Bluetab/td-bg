defmodule TdBg.RolesAdminTest do
  use Cabbage.Feature, async: false, file: "roles_admin.feature"
  use TdBgWeb.FeatureCase
  import TdBgWeb.Router.Helpers
  import TdBgWeb.ResponseCode
  import TdBgWeb.Taxonomy
  import TdBgWeb.Authentication, only: :functions
  import TdBgWeb.User, only: :functions
  alias TdBgWeb.ApiServices.MockTdAuthService
  alias Poison, as: JSON
  @endpoint TdBgWeb.Endpoint

  setup_all do
    start_supervised MockTdAuthService
    :ok
  end

  setup do
    on_exit fn ->
      MockTdAuthService.set_users([])
    end
  end

  #Scenario
  defgiven ~r/^an existing Domain Group called "(?<name>[^"]+)"$/, %{name: name}, state do
    token_admin = get_user_token("app-admin")
    state = Map.merge(state, %{token_admin: token_admin})
    {:ok, status_code, _json_resp} = domain_group_create(state[:token_admin],  %{name: name})
    assert rc_created() == to_response_code(status_code)
    {:ok, state}
  end

  defand ~r/^an existing Data Domain called "(?<name>[^"]+)" child of Domain Group "(?<domain_group_name>[^"]+)"$/,
    %{name: name, domain_group_name: domain_group_name}, state do
    domain_group_info = get_domain_group_by_name(state[:token_admin], domain_group_name)
    {:ok, _status_code, json_resp} = data_domain_create(state[:token_admin],  %{name: name, domain_group_id: domain_group_info["id"]})
    assert json_resp["data"]["domain_group_id"] == domain_group_info["id"]
    {:ok, state}
  end

  defand ~r/^following users exist with the indicated role in Domain Group "(?<domain_group_name>[^"]+)"$/,
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

  defwhen ~r/^"(?<user_name>[^"]+)" grants (?<role_name>[^"]+) role to user "(?<principal_name>[^"]+)" in Domain Group "(?<resource_name>[^"]+)"$/,
    %{user_name: user_name, role_name: role_name, principal_name: principal_name, resource_name: resource_name}, state do

    domain_group_info = get_domain_group_by_name(state[:token_admin], resource_name)
    principal_id = create_user(principal_name).id
    role_info = get_role_by_name(state[:token_admin], role_name)
    acl_entry_params = %{principal_type: "user", principal_id: principal_id, resource_type: "domain_group", resource_id: domain_group_info["id"], role_id: role_info["id"]}

    token = get_user_token(user_name)
    {_, status_code, json_resp} = acl_entry_create(token , acl_entry_params)
    {:ok, Map.merge(state, %{status_code: status_code,  resp: json_resp})}
  end

  defthen ~r/^the system returns a result with code "(?<status_code>[^"]+)"$/, %{status_code: status_code}, state do
    assert status_code == to_response_code(state[:status_code])
  end

  #And if result <result> is "Created", Data Domain "My Data Domain" is a child of Domain Group "My Group"
  defand ~r/^if result "(?<actual_result>[^"]+)" is "(?<expected_result>[^"]+)", the user "(?<user_name>[^"]+)" has "(?<role_name>[^"]+)" role in Domain Group "(?<domain_group_name>[^"]+)"$/,
    %{actual_result: actual_result, expected_result: expected_result, user_name: user_name, role_name: role_name, domain_group_name: domain_group_name}, state do
    if actual_result == expected_result do
      domain_group_info = get_domain_group_by_name(state[:token_admin], domain_group_name)
      principal_id = get_user_by_name(user_name).id
      acl_entry_params = %{user_id: principal_id, domain_group_id: domain_group_info["id"]}
      {:ok, _status_code, json_resp} = user_domain_group_role(state[:token_admin], acl_entry_params)
      assert json_resp["data"]["name"] == role_name
    end
  end

  #And if result <result> is "Created", Data Domain "My Data Domain" is a child of Domain Group "My Group"
  defand ~r/^if result "(?<actual_result>[^"]+)" is "(?<expected_result>[^"]+)", the user "(?<user_name>[^"]+)" has "(?<role_name>[^"]+)" role in Data Domain "(?<data_domain_name>[^"]+)"$/,
    %{actual_result: actual_result, expected_result: expected_result, user_name: user_name, role_name: role_name, data_domain_name: data_domain_name}, state do
    if actual_result == expected_result do
      data_domain_info = get_data_domain_by_name(state[:token_admin], data_domain_name)
      principal_id = get_user_by_name(user_name).id
      acl_entry_params = %{user_id: principal_id, data_domain_id: data_domain_info["id"]}
      {:ok, _status_code, json_resp} = user_data_domain_role(state[:token_admin], acl_entry_params)
      assert json_resp["data"]["name"] == role_name
    end
  end

  defand ~r/^following users exist with the indicated role in Data Domain "(?<data_domain_name>[^"]+)"$/,
         %{data_domain_name: data_domain_name, table: table}, state do

    data_domain = get_data_domain_by_name(state[:token_admin], data_domain_name)
    Enum.map(table, fn(x) ->
      user_name = x[:user]
      role_name = x[:role]
      principal_id = find_or_create_user(user_name).id
      %{"id" => role_id} = get_role_by_name(state[:token_admin], role_name)
      acl_entry_params = %{principal_type: "user", principal_id: principal_id, resource_type: "data_domain", resource_id: data_domain["id"], role_id: role_id}
      {:ok, _, _json_resp} = acl_entry_create(state[:token_admin], acl_entry_params)
      {:ok, _, json_resp} = user_data_domain_role(state[:token_admin], %{user_id: principal_id, data_domain_id: data_domain["id"]})
      assert json_resp["data"]["name"] == role_name
    end)
  end

  defwhen ~r/^"(?<user_name>[^"]+)" grants (?<role_name>[^"]+) role to user "(?<principal_name>[^"]+)" in Data Domain "(?<resource_name>[^"]+)"$/,
          %{user_name: user_name, role_name: role_name, principal_name: principal_name, resource_name: resource_name}, state do

    data_domain_info = get_data_domain_by_name(state[:token_admin], resource_name)
    principal_id = find_or_create_user(principal_name).id
    role_info = get_role_by_name(state[:token_admin], role_name)
    acl_entry_params = %{principal_type: "user", principal_id: principal_id, resource_type: "data_domain", resource_id: data_domain_info["id"], role_id: role_info["id"]}

    token = get_user_token(user_name)
    {_, status_code, json_resp} = acl_entry_create(token , acl_entry_params)
    {:ok, Map.merge(state, %{status_code: status_code,  resp: json_resp})}
  end

  defwhen ~r/^"(?<user_name>[^"]+)" lists all users with custom permissions in Data Domain "(?<data_domain_name>[^"]+)"$/,
    %{user_name: user_name, data_domain_name: data_domain_name}, state do
    token = get_user_token(user_name)
    data_domain_info = get_data_domain_by_name(token, data_domain_name)
    {:ok, 200,  %{"data" => users_roles}} = data_domain_users_roles(token, %{id: data_domain_info["id"]})
    {:ok, Map.merge(state, %{users_roles: users_roles})}
  end

  defthen ~r/^the system returns a result with following data:$/,
    %{table: expected_list}, state do

    actual_list = state[:users_roles]
    expected_list = Enum.reduce(expected_list, [], fn(item, acc) ->
      nitem = Map.new(item, fn {k, v} -> {Atom.to_string(k), v} end)
      acc ++ [nitem]
    end
    )
    assert length(expected_list) == length(actual_list)
    Enum.each(expected_list, fn(e_user_role_entry) ->
      user_role = Enum.find(actual_list, fn(c_user_role_entry) ->
        e_user_role_entry["user"] == c_user_role_entry["user_name"]
      end)
      assert user_role["user_name"] == e_user_role_entry["user"] &&
        user_role["role_name"] == e_user_role_entry["role"]
    end)
  end

  defand ~r/^following users exist in the application:$/, %{table: users}, _state do
    Enum.each(users, &(create_user(&1.user)))
  end

  defwhen ~r/^"(?<user_name>[^"]+)" tries to list all users available to set custom permissions in Domain Group "(?<domain_group>[^"]+)"$/,
          %{user_name: user_name, domain_group: domain_group_name}, state do
    token = get_user_token(user_name)
    headers = get_header(token)
    domain_group = get_domain_group_by_name(token, domain_group_name)
    {:ok, %HTTPoison.Response{status_code: status_code, body: resp}} =
      HTTPoison.get(domain_group_domain_group_url(@endpoint, :available_users, domain_group["id"]), headers, [])
    users = resp |> JSON.decode!
    {:ok, Map.merge(state, %{status_code: status_code, users: users})}
  end

  defthen ~r/^the system returns an user list with following data:$/, %{table: users}, state do
    available_users = state[:users]["data"]
    assert length(users) == length(available_users)

    Enum.each(users, fn(user) ->
      match_user = Enum.find(available_users, fn(available) ->
        user.user == available["user_name"]
      end)
      assert match_user
    end)
  end

  defand ~r/^an existing user "(?<user_name>[^"]+)" with password "(?<password>[^"]+)" with super-admin property "(?<is_admin>[^"]+)"$/,
         %{user_name: user_name, password: password, is_admin: is_admin}, _state do
    super_user = create_user(user_name, password: password, is_admin: is_admin_bool(is_admin))
    assert super_user != nil
  end

  defwhen ~r/"(?<user_name>[^"]+)" tries to list all users available to set custom permissions in Data Domain "(?<data_domain>[^"]+)"$/,
          %{user_name: user_name, data_domain: data_domain_name}, state do
    token = get_user_token(user_name)
    headers = get_header(token)
    data_domain = get_data_domain_by_name(token, data_domain_name)
    {:ok, %HTTPoison.Response{status_code: status_code, body: resp}} =
      HTTPoison.get(data_domain_data_domain_url(@endpoint, :available_users, data_domain["id"]), headers, [])
    users = resp |> JSON.decode!
    {:ok, Map.merge(state, %{status_code: status_code, users: users})}
  end

  #Scenario List of user with custom permission in a Domain Group
  defgiven ~r/^an existing Domain Group called "(?<name>[^"]+)"$/, %{name: name}, state do
    token_admin = get_user_token("app-admin")
    state = Map.merge(state, %{token_admin: token_admin})
    {:ok, status_code, _json_resp} = domain_group_create(state[:token_admin],  %{name: name})
    assert rc_created() == to_response_code(status_code)
    {:ok, state}
  end

  defand ~r/^following users exist with the indicated role in Domain Group "(?<domain_group_name>[^"]+)"$/,
    %{domain_group_name: domain_group_name, table: table}, state do

    domain_group = get_domain_group_by_name(state[:token_admin], domain_group_name)
    Enum.map(table, fn(x) ->
        user_name = x[:user]
        role_name = x[:role]
        principal_id = find_or_create_user(user_name).id
        %{"id" => role_id} = get_role_by_name(state[:token_admin], role_name)
        acl_entry_params = %{principal_type: "user", principal_id: principal_id, resource_type: "domain_group", resource_id: domain_group["id"], role_id: role_id}
        {:ok, 201, _json_resp} = acl_entry_create(state[:token_admin], acl_entry_params)
        {:ok, 200, json_resp} = user_domain_group_role(state[:token_admin], %{user_id: principal_id, domain_group_id: domain_group["id"]})
        assert json_resp["data"]["name"] == role_name
      end)
  end

  defwhen ~r/^"(?<user_name>[^"]+)" lists all users with custom permissions in Domain Group "(?<domain_group_name>[^"]+)"$/,
  %{user_name: user_name, domain_group_name: domain_group_name}, state do
    token = get_user_token(user_name)
    domain_group_info = get_domain_group_by_name(token, domain_group_name)
    {:ok, 200,  %{"data" => users_roles}} = domain_group_users_roles(token, %{id: domain_group_info["id"]})
    {:ok, Map.merge(state, %{users_roles: users_roles})}
  end

  defthen ~r/^the system returns a result with following data:$/,
    %{table: expected_list}, state do

    actual_list = state[:users_roles]
    expected_list = Enum.reduce(expected_list, [], fn(item, acc) ->
      nitem = Map.new(item, fn {k, v} -> {Atom.to_string(k), v} end)
      acc ++ [nitem]
    end
    )
    assert length(expected_list) == length(actual_list)
    Enum.each(expected_list, fn(e_user_role_entry) ->
      user_role = Enum.find(actual_list, fn(c_user_role_entry) ->
        e_user_role_entry["user"] == c_user_role_entry["user_name"]
      end)
      assert user_role["user_name"] == e_user_role_entry["user"] &&
        user_role["role_name"] == e_user_role_entry["role"]
    end)
  end

  defand ~r/^an existing Domain Group called "(?<name>[^"]+)" child of Domain Group "(?<domain_group_name>[^"]+)"$/, %{name: name, domain_group_name: domain_group_name}, state do
    domain_group_info = get_domain_group_by_name(state[:token_admin], domain_group_name)
    {:ok, status_code, json_resp} = domain_group_create(state[:token_admin],  %{name: name, parent_id: domain_group_info["id"]})
    assert rc_created() == to_response_code(status_code)
    assert json_resp["data"]["parent_id"] == domain_group_info["id"]
    {:ok, state}
  end

  defwhen ~r/^user "(?<user_name>[^"]+)" lists taxonomy roles of user "(?<target_user_name>[^"]+)"$/,
    %{user_name: user_name, target_user_name: target_user_name},
    state do
    token = get_user_token(user_name)
    principal_id = find_or_create_user(target_user_name).id
    {:ok, 200,  %{"data" => taxonomy_roles}} = get_taxonomy_roles(token, %{principal_id: principal_id})
    {:ok, Map.merge(state, %{taxonomy_roles: taxonomy_roles, token: token})}
  end

  defthen ~r/^the system returns a taxonomy roles list with following data:$/,
    %{table: expected_list},
    state do
    actual_list = state[:taxonomy_roles]

    expected_list = Enum.map(expected_list, fn(role_entry) ->
      node_id = case {role_entry.type, role_entry.parent_name} do
            {"DG", ""} -> get_domain_group_by_name(state[:token], role_entry.name)["id"]
            {"DG", parent_name} ->
              parent = get_domain_group_by_name(state[:token], parent_name)
              get_domain_group_by_name_and_parent(state[:token], role_entry.name, parent["id"])["id"]
            {"DD", parent_name} ->
              parent = get_domain_group_by_name(state[:token], parent_name)
              get_data_domain_by_name_and_parent(state[:token], role_entry.name, parent["id"])["id"]
            _ -> nil
      end
      %{id: node_id, type: role_entry.type, inherited: role_entry.inherited == "true", role: role_entry.role}
    end)
    expected_list = Enum.group_by(expected_list, &(&1.type), &(%{"id" => &1.id, "role" => &1.role, "inherited" => &1.inherited}))
    roles_dg = expected_list["DG"]
    roles_dg = case roles_dg do
      nil -> %{}
      _ -> roles_dg |> Enum.reduce(%{}, fn(x, acc) -> Map.put(acc, to_string(x["id"]), %{"role" => x["role"], "inherited" => x["inherited"]}) end)
    end
    roles_dd = expected_list["DD"]
    roles_dd = case roles_dd do
      nil -> %{}
      _ -> roles_dd |> Enum.reduce(%{}, fn(x, acc) -> Map.put(acc, to_string(x["id"]), %{"role" => x["role"], "inherited" => x["inherited"]}) end)
    end

    actual_list = %{"domain_groups" => remove_acl_entry_id(actual_list["domain_groups"]), "data_domains" => remove_acl_entry_id(actual_list["data_domains"])}
    expected_list = %{"domain_groups" => roles_dg, "data_domains" => roles_dd}
    assert JSONDiff.diff(actual_list, expected_list) == []
  end

  defp remove_acl_entry_id(role_entries) do
    Enum.reduce(Map.keys(role_entries), %{}, fn(resource_id, acc) ->
     Map.put(acc, resource_id, Map.delete(role_entries[resource_id], "acl_entry_id"))
    end)
  end

  defp data_domain_users_roles(token, attrs) do
    headers = get_header(token)
    %HTTPoison.Response{status_code: status_code, body: resp} =
      HTTPoison.get!(data_domain_data_domain_url(@endpoint, :users_roles, attrs.id), headers, [])
    {:ok, status_code, resp |> JSON.decode!}
  end

  defp domain_group_users_roles(token, attrs) do
    headers = get_header(token)
    %HTTPoison.Response{status_code: status_code, body: resp} =
      HTTPoison.get!(domain_group_domain_group_url(@endpoint, :users_roles, attrs.id), headers, [])
    {:ok, status_code, resp |> JSON.decode!}
  end

  defp get_taxonomy_roles(token, attrs) do
    headers = get_header(token)
    %HTTPoison.Response{status_code: status_code, body: resp} =
      HTTPoison.get!(taxonomy_url(@endpoint, :roles, principal_id: attrs.principal_id), headers, [])
    {:ok, status_code, resp |> JSON.decode!}
  end

  defp user_domain_group_role(token, attrs) do
    headers = get_header(token)
    %HTTPoison.Response{status_code: status_code, body: resp} =
      HTTPoison.get!(user_domain_group_role_url(@endpoint, :user_domain_group_role, attrs.user_id, attrs.domain_group_id), headers, [])
    {:ok, status_code, resp |> JSON.decode!}
  end

  defp user_data_domain_role(token, attrs) do
    headers = get_header(token)
    %HTTPoison.Response{status_code: status_code, body: resp} =
      HTTPoison.get!(user_data_domain_role_url(@endpoint, :user_data_domain_role, attrs.user_id, attrs.data_domain_id), headers, [])
    {:ok, status_code, resp |> JSON.decode!}
  end

  defp acl_entry_create(token, acl_entry_params) do
    headers = get_header(token)
    body = %{acl_entry: acl_entry_params} |> JSON.encode!
    %HTTPoison.Response{status_code: status_code, body: resp} =
      HTTPoison.post!(acl_entry_url(@endpoint, :create), body, headers, [])
    {:ok, status_code, resp |> JSON.decode!}
  end
end
