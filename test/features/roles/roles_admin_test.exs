defmodule TdBg.RolesAdminTest do
  use Cabbage.Feature, async: false, file: "roles/roles_admin.feature"
  use TdBgWeb.FeatureCase
  import TdBgWeb.Router.Helpers
  import TdBgWeb.ResponseCode
  import TdBgWeb.Taxonomy
  import TdBgWeb.Authentication, only: :functions
  import TdBgWeb.User, only: :functions
  alias TdBgWeb.ApiServices.MockTdAuthService
  alias Poison, as: JSON

  import_steps(TdBg.DomainSteps)
  import_steps(TdBg.ResultSteps)
  import_steps(TdBg.UsersSteps)

  import TdBg.ResultSteps

  setup_all do
    start_supervised(MockTdAuthService)
    :ok
  end

  setup do
    on_exit(fn ->
      MockTdAuthService.set_users([])
    end)
  end

  defwhen ~r/^"(?<user_name>[^"]+)" grants (?<role_name>[^"]+) role to user "(?<principal_name>[^"]+)" in Domain Group "(?<resource_name>[^"]+)"$/,
          %{
            user_name: user_name,
            role_name: role_name,
            principal_name: principal_name,
            resource_name: resource_name
          },
          state do
    domain_info = get_domain_by_name(state[:token_admin], resource_name)
    principal_id = create_user(principal_name).id
    role_info = get_role_by_name(state[:token_admin], role_name)

    acl_entry_params = %{
      principal_type: "user",
      principal_id: principal_id,
      resource_type: "domain",
      resource_id: domain_info["id"],
      role_id: role_info["id"]
    }

    token = get_user_token(user_name)
    {_, status_code, json_resp} = acl_entry_create(token, acl_entry_params)
    {:ok, Map.merge(state, %{status_code: status_code, resp: json_resp})}
  end

  defand ~r/^if result "(?<actual_result>[^"]+)" is "(?<expected_result>[^"]+)", the user "(?<user_name>[^"]+)" has "(?<role_name>[^"]+)" role in Domain "(?<domain_name>[^"]+)"$/,
         %{
           actual_result: actual_result,
           expected_result: expected_result,
           user_name: user_name,
           role_name: role_name,
           domain_name: domain_name
         },
         state do
    if actual_result == expected_result do
      domain_info = get_domain_by_name(state[:token_admin], domain_name)
      principal_id = get_user_by_name(user_name).id
      acl_entry_params = %{user_id: principal_id, domain_id: domain_info["id"]}
      {:ok, _status_code, json_resp} = user_domain_role(state[:token_admin], acl_entry_params)
      assert Enum.member?(Enum.map(json_resp["data"], & &1["name"]), role_name)
    end
  end

  defwhen ~r/^"(?<user_name>[^"]+)" lists all users with custom permissions in Domain "(?<domain_name>[^"]+)"$/,
          %{user_name: user_name, domain_name: domain_name},
          state do
    token = get_user_token(user_name)
    domain_info = get_domain_by_name(token, domain_name)
    {:ok, 200, %{"data" => acl_entries}} = domain_acl_entries(token, %{id: domain_info["id"]})
    {:ok, Map.merge(state, %{acl_entries: acl_entries})}
  end

  defand ~r/^following users exist in the application:$/, %{table: users}, _state do
    Enum.each(users, &create_user(&1.user))
  end

  defwhen ~r/^"(?<user_name>[^"]+)" tries to list all users available to set custom permissions in Domain Group "(?<domain>[^"]+)"$/,
          %{user_name: user_name, domain: domain_name},
          state do
    token = get_user_token(user_name)
    headers = get_header(token)
    domain = get_domain_by_name(token, domain_name)

    {:ok, %HTTPoison.Response{status_code: status_code, body: resp}} =
      HTTPoison.get(domain_domain_url(@endpoint, :available_users, domain["id"]), headers, [])

    users = resp |> JSON.decode!()
    {:ok, Map.merge(state, %{status_code: status_code, users: users})}
  end

  defthen ~r/^the system returns an user list with following data:$/, %{table: users}, state do
    available_users = state[:users]["data"]
    assert length(users) == length(available_users)

    Enum.each(users, fn user ->
      match_user =
        Enum.find(available_users, fn available ->
          user.user == available["user_name"]
        end)

      assert match_user
    end)
  end

  defand ~r/^an existing user "(?<user_name>[^"]+)" with password "(?<password>[^"]+)" with super-admin property "(?<is_admin>[^"]+)"$/,
         %{user_name: user_name, password: password, is_admin: is_admin},
         _state do
    super_user = create_user(user_name, password: password, is_admin: is_admin_bool(is_admin))
    assert super_user != nil
  end

  defwhen ~r/"(?<user_name>[^"]+)" tries to list all users available to set custom permissions in Domain "(?<domain>[^"]+)"$/,
          %{user_name: user_name, domain: domain_name},
          state do
    token = get_user_token(user_name)
    headers = get_header(token)
    domain = get_domain_by_name(token, domain_name)

    {:ok, %HTTPoison.Response{status_code: status_code, body: resp}} =
      HTTPoison.get(domain_domain_url(@endpoint, :available_users, domain["id"]), headers, [])

    users = resp |> JSON.decode!()
    {:ok, Map.merge(state, %{status_code: status_code, users: users})}
  end

  defthen ~r/^the system returns a result with following data:$/,
          %{table: expected_list},
          state do
    actual_list = state[:acl_entries]

    expected_list =
      Enum.reduce(expected_list, [], fn item, acc ->
        nitem = Map.new(item, fn {k, v} -> {Atom.to_string(k), v} end)
        acc ++ [nitem]
      end)

    assert length(expected_list) == length(actual_list)

    Enum.each(expected_list, fn e_user_role_entry ->
      user_role =
        Enum.find(actual_list, fn c_user_role_entry ->
          e_user_role_entry["user"] == c_user_role_entry["principal"]["user_name"]
        end)

      assert user_role["principal"]["user_name"] == e_user_role_entry["user"] &&
               user_role["role_name"] == e_user_role_entry["role"]
    end)
  end

  defp remove_acl_entry_id(role_entries) do
    Enum.reduce(Map.keys(role_entries), %{}, fn resource_id, acc ->
      reduced_map = Map.delete(role_entries[resource_id], "acl_entry_id")
      reduced_map = Map.delete(reduced_map, "role_id")
      Map.put(acc, resource_id, reduced_map)
    end)
  end

  defp domain_acl_entries(token, attrs) do
    headers = get_header(token)

    %HTTPoison.Response{status_code: status_code, body: resp} =
      HTTPoison.get!(domain_domain_url(TdBgWeb.Endpoint, :acl_entries, attrs.id), headers, [])

    {:ok, status_code, resp |> JSON.decode!()}
  end

  defp user_domain_role(token, attrs) do
    headers = get_header(token)

    %HTTPoison.Response{status_code: status_code, body: resp} =
      HTTPoison.get!(
        user_domain_role_url(TdBgWeb.Endpoint, :user_domain_role, attrs.user_id, attrs.domain_id),
        headers,
        []
      )

    {:ok, status_code, resp |> JSON.decode!()}
  end

  defp acl_entry_create(token, acl_entry_params) do
    headers = get_header(token)
    body = %{acl_entry: acl_entry_params} |> JSON.encode!()

    %HTTPoison.Response{status_code: status_code, body: resp} =
      HTTPoison.post!(acl_entry_url(TdBgWeb.Endpoint, :create), body, headers, [])

    {:ok, status_code, resp |> JSON.decode!()}
  end
end
