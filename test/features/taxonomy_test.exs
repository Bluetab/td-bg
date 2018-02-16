defmodule TrueBG.TaxonomyTest do
  use Cabbage.Feature, async: false, file: "taxonomy.feature"
  use TrueBGWeb.ConnCase
  import TrueBGWeb.ResponseCode
  import TrueBGWeb.Taxonomy
  import TrueBGWeb.User, only: :functions
  import TrueBGWeb.Authentication, only: :functions
  import TrueBGWeb.AclEntry, only: :functions

  defand ~r/^an existing Domain Group called "(?<domain_group_name>[^"]+)"$/,
     %{domain_group_name: name}, state do

    token_admin = build_user_token("app-admin", is_admin: true)
    state = Map.merge(state, %{token_admin: token_admin})
    {:ok, status_code, _json_resp} = domain_group_create(token_admin,  %{name: name})
    assert rc_created() == to_response_code(status_code)
    {:ok, state}
  end

  defand ~r/^following users exist with the indicated role in Domain Group "(?<domain_group_name>[^"]+)"$/,
     %{domain_group_name: domain_group_name, table: table}, %{token_admin: token_admin} = state do

    domain_group = get_domain_group_by_name(token_admin, domain_group_name)
    assert domain_group_name == domain_group["name"]

    create_user_and_acl_entries_fn = fn(x) ->
      user_name = x[:user]
      role_name = x[:role]
      principal_id = create_user(user_name).id
      %{"id" => role_id} = get_role_by_name(token_admin, role_name)
      acl_entry_params = %{principal_type: "user", principal_id: principal_id, resource_type: "domain_group", resource_id: domain_group["id"], role_id: role_id}
      {_, _status_code, _json_resp} = acl_entry_create(token_admin , acl_entry_params)
    end

    users = table |> Enum.map(create_user_and_acl_entries_fn)

    {:ok, Map.merge(state, %{users: users})}
  end

  # Scenario: Creating a Data Domain depending on an existing Domain Group
  defwhen ~r/^user "(?<user_name>[^"]+)" tries to create a Data Domain with the name "(?<data_domain_name>[^"]+)" as child of Domain Group "(?<domain_group_name>[^"]+)" with following data:$/,
    %{user_name: user_name, data_domain_name: data_domain_name, domain_group_name: domain_group_name, table: [%{Description: description}]}, %{token_admin: token_admin} = state do

    parent = get_domain_group_by_name(token_admin, domain_group_name)
    assert parent["name"] == domain_group_name
    token = build_user_token(user_name)
    {_, status_code, _json_resp} = data_domain_create(token, %{name: data_domain_name, description: description, domain_group_id: parent["id"]})
    {:ok, Map.merge(state, %{status_code: status_code})}
  end

  defthen ~r/^the system returns a result with code "(?<status_code>[^"]+)"$/,
          %{status_code: status_code}, %{status_code: http_status_code} = state do
    assert status_code == to_response_code(http_status_code)
    {:ok, Map.merge(state, %{})}
  end

  defand ~r/^if result (?<actual_result>[^"]+) is "(?<expected_result>[^"]+)", user (?<user_name>[^"]+) is able to see the Data Domain "(?<data_domain_name>[^"]+)" with following data:$/,
         %{actual_result: actual_result, expected_result: expected_result, user_name: user_name, data_domain_name: data_domain_name, table: [%{Description: description}]},
         state do
    if actual_result == expected_result do
      token  = build_user_token(user_name)
      data_domain_info = get_data_domain_by_name(token, data_domain_name)
      assert data_domain_name == data_domain_info["name"]
      {:ok, status_code, json_resp} = data_domain_show(token, data_domain_info["id"])
      assert rc_ok() == to_response_code(status_code)
      data_domain = json_resp["data"]
      assert data_domain_name == data_domain["name"]
      assert description == data_domain["description"]
      {:ok, %{state | status_code: nil}}
    end
  end

  #And if result <result> is "Created", Data Domain "My Data Domain" is a child of Domain Group "My Group"
  defand ~r/^if result (?<actual_result>[^"]+) is "(?<expected_result>[^"]+)", Data Domain "(?<data_domain_name>[^"]+)" is a child of Domain Group "(?<domain_group_name>[^"]+)"$/,
    %{actual_result: actual_result, expected_result: expected_result, data_domain_name: data_domain_name, domain_group_name: domain_group_name}, state do
    if actual_result == expected_result do
      data_domain_info = get_data_domain_by_name(state[:token_admin], data_domain_name)
      domain_group_info = get_domain_group_by_name(state[:token_admin], domain_group_name)
      assert data_domain_info["domain_group_id"] == domain_group_info["id"]
    end

  end

end
