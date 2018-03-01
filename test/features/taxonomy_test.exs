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
    %{user_name: user_name, data_domain_name: data_domain_name, domain_group_name: domain_group_name, table: [%{Description: description}]},
    %{token_admin: token_admin} = state do

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

  defand ~r/^if result (?<actual_result>[^"]+) is "(?<expected_result>[^"]+)", user "(?<user_name>[^"]+)" is able to see the Data Domain "(?<data_domain_name>[^"]+)" with following data:$/,
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

  defand ~r/^if result (?<actual_result>[^"]+) is not "(?<expected_result>[^"]+)", user "(?<user_name>[^"]+)" is able to see the Data Domain "(?<data_domain_name>[^"]+)" with following data:$/,
    %{actual_result: actual_result, expected_result: expected_result, user_name: user_name, data_domain_name: data_domain_name, table: [%{Description: description}]},
    state do
    if actual_result != expected_result do
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

  defwhen ~r/^user "(?<user_name>[^"]+)" tries to create a Domain Group with the name "(?<new_domain_group_name>[^"]+)" as child of Domain Group "(?<domain_group_name>[^"]+)" with following data:$/,
          %{user_name: user_name, new_domain_group_name: new_domain_group_name, domain_group_name: domain_group_name, table: [%{Description: description}]}, %{token_admin: token_admin} = state do
    parent = get_domain_group_by_name(token_admin, domain_group_name)
    assert parent["name"] == domain_group_name
    token = build_user_token(user_name)
    {_, status_code, _json_resp} = domain_group_create(token, %{name: new_domain_group_name, description: description, parent_id: parent["id"]})
    {:ok, Map.merge(state, %{status_code: status_code})}
  end

  defand ~r/^if result (?<actual_result>[^"]+) is "(?<expected_result>[^"]+)", user "(?<user_name>[^"]+)" is able to see the Domain Group "(?<domain_group_name>[^"]+)" with following data:$/,
    %{actual_result: actual_result, expected_result: expected_result, user_name: user_name, domain_group_name: domain_group_name, table: [%{Description: description}]},
    state do
    if actual_result == expected_result do
      token  = build_user_token(user_name)
      domain_group_info = get_domain_group_by_name(token, domain_group_name)
      assert domain_group_name == domain_group_info["name"]
      {:ok, status_code, json_resp} = domain_group_show(token, domain_group_info["id"])
      assert rc_ok() == to_response_code(status_code)
      domain_group = json_resp["data"]
      assert domain_group_name == domain_group["name"]
      assert description == domain_group["description"]
      {:ok, %{state | status_code: nil}}
    end
  end

  defand ~r/^if result (?<actual_result>[^"]+) is not "(?<expected_result>[^"]+)", user "(?<user_name>[^"]+)" is able to see the Domain Group "(?<domain_group_name>[^"]+)" with following data:$/,
    %{actual_result: actual_result, expected_result: expected_result, user_name: user_name, domain_group_name: domain_group_name, table: [%{Description: description}]},
    state do
    if actual_result != expected_result do
      token  = build_user_token(user_name)
      domain_group_info = get_domain_group_by_name(token, domain_group_name)
      assert domain_group_name == domain_group_info["name"]
      {:ok, status_code, json_resp} = domain_group_show(token, domain_group_info["id"])
      assert rc_ok() == to_response_code(status_code)
      domain_group = json_resp["data"]
      assert domain_group_name == domain_group["name"]
      assert description == domain_group["description"]
      {:ok, %{state | status_code: nil}}
    end
  end

  defand ~r/^if result (?<actual_result>[^"]+) is "(?<expected_result>[^"]+)", Domain Group "(?<domain_group_name>[^"]+)" is a child of Domain Group "(?<parent_domain_group_name>[^"]+)"$/,
    %{actual_result: actual_result, expected_result: expected_result, domain_group_name: domain_group_name, parent_domain_group_name: parent_domain_group_name}, state do
    if actual_result == expected_result do
      domain_group_info = get_domain_group_by_name(state[:token_admin], domain_group_name)
      parent_domain_group_info = get_domain_group_by_name(state[:token_admin], parent_domain_group_name)
      assert domain_group_info["parent_id"] == parent_domain_group_info["id"]
    end
  end

  defand ~r/^an existing Domain Group called "(?<name>[^"]+)" child of Domain Group "(?<domain_group_name>[^"]+)"$/,
    %{name: name, domain_group_name: domain_group_name}, state do
    domain_group_info = get_domain_group_by_name(state[:token_admin], domain_group_name)
    {:ok, status_code, json_resp} = domain_group_create(state[:token_admin],  %{name: name, parent_id: domain_group_info["id"]})
    assert rc_created() == to_response_code(status_code)
    assert json_resp["data"]["parent_id"] == domain_group_info["id"]
    {:ok, state}
  end

  defand ~r/^an existing Domain Group called "(?<name>[^"]+)" child of Domain Group "(?<domain_group_name>[^"]+)" with following data:$/,
    %{name: name, domain_group_name: domain_group_name, table: [%{Description: description}]}, state do
    domain_group_info = get_domain_group_by_name(state[:token_admin], domain_group_name)
    {:ok, status_code, json_resp} = domain_group_create(state[:token_admin],  %{name: name, description: description, parent_id: domain_group_info["id"]})
    assert rc_created() == to_response_code(status_code)
    assert json_resp["data"]["parent_id"] == domain_group_info["id"]
    {:ok, state}
  end

  defand ~r/^user "(?<user_name>[^"]+)" tries to modify a Domain Group with the name "(?<domain_group_name>[^"]+)" introducing following data:$/,
    %{user_name: user_name, domain_group_name: domain_group_name, table: [%{Description: description}]}, state do
    token = get_user_token(user_name)
    domain_group = get_domain_group_by_name(token, domain_group_name)
    {_, status_code, _json_resp} = domain_group_update(token, domain_group["id"], %{name: domain_group_name, description: description})
    {:ok, Map.merge(state, %{status_code: status_code})}
  end

  defand ~r/^an existing Data Domain called "(?<data_domain_name>[^"]+)" child of Domain Group "(?<domain_group_name>[^"]+)"$/,
         %{data_domain_name: data_domain_name, domain_group_name: domain_group_name}, state do
    token_admin = build_user_token("app-admin", is_admin: true)
    domain_group = get_domain_group_by_name(token_admin, domain_group_name)
    assert domain_group && domain_group["id"]
    {_, _status_code, json_resp} = data_domain_create(token_admin, %{name: data_domain_name, domain_group_id: domain_group["id"]})
    data_domain = json_resp["data"]
    assert data_domain["domain_group_id"] == domain_group["id"]
    state = Map.merge(state, %{token_admin: token_admin})
    {:ok, state}
  end

  defand ~r/^an existing Data Domain called "(?<data_domain_name>[^"]+)" child of Domain Group "(?<domain_group_name>[^"]+)" with following data:$/,
    %{data_domain_name: data_domain_name, domain_group_name: domain_group_name, table: [%{Description: description}]}, state do
    token_admin = build_user_token("app-admin", is_admin: true)
    domain_group = get_domain_group_by_name(token_admin, domain_group_name)
    assert domain_group && domain_group["id"]
    {_, _status_code, json_resp} = data_domain_create(token_admin, %{name: data_domain_name, description: description, domain_group_id: domain_group["id"]})
    data_domain = json_resp["data"]
    assert data_domain["domain_group_id"] == domain_group["id"]
    assert data_domain["description"] == description
    state = Map.merge(state, %{token_admin: token_admin})
    {:ok, state}
  end

  defand ~r/^following users exist with the indicated role in Data Domain "(?<data_domain_name>[^"]+)"$/,
    %{data_domain_name: data_domain_name, table: table}, %{token_admin: token_admin} = state do

    data_domain = get_data_domain_by_name(token_admin, data_domain_name)
    assert data_domain_name == data_domain["name"]

    create_user_and_acl_entries_fn = fn(x) ->
      user_name = x[:user]
      role_name = x[:role]
      principal_id = create_user(user_name).id
      %{"id" => role_id} = get_role_by_name(token_admin, role_name)
      acl_entry_params = %{principal_type: "user", principal_id: principal_id, resource_type: "data_domain", resource_id: data_domain["id"], role_id: role_id}
      {_, _status_code, _json_resp} = acl_entry_create(token_admin , acl_entry_params)
    end

    users = table |> Enum.map(create_user_and_acl_entries_fn)

    {:ok, Map.merge(state, %{users: users})}
  end

  defwhen ~r/^user "(?<user_name>[^"]+)" tries to modify a Data Domain with the name "(?<data_domain_name>[^"]+)" introducing following data:$/,
    %{user_name: user_name, data_domain_name: data_domain_name, table: [%{Description: description}]}, state do
    token = get_user_token(user_name)
    data_domain_info = get_data_domain_by_name(token, data_domain_name)
    {:ok, status_code, _json_resp} = data_domain_update(token, data_domain_info["id"], %{name: data_domain_name, description: description})
    {:ok, Map.merge(state, %{status_code: status_code})}
  end

  defwhen ~r/^user "(?<user_name>[^"]+)" tries to delete a Domain Group with the name "(?<domain_group_name>[^"]+)"$/,
    %{user_name: user_name, domain_group_name: domain_group_name}, state do

    token = get_user_token(user_name)
    domain_group_info = get_domain_group_by_name(token, domain_group_name)
    {:ok, status_code} = domain_group_delete(token, domain_group_info["id"])
    {:ok, Map.merge(state, %{status_code: status_code})}
  end

  defand ~r/^if result (?<actual_result>[^"]+) is "(?<expected_result>[^"]+)", Data Domain "(?<data_domain_name>[^"]+)" is a child of Domain Group "(?<domain_group_name>[^"]+)"$/,
         %{actual_result: actual_result, expected_result: expected_result, data_domain_name: data_domain_name, domain_group_name: domain_group_name}, state do
    if actual_result == expected_result do
      data_domain_info = get_data_domain_by_name(state[:token_admin], data_domain_name)
      domain_group_info = get_domain_group_by_name(state[:token_admin], domain_group_name)
      assert data_domain_info["domain_group_id"] == domain_group_info["id"]
    end
  end

  defand ~r/^if result (?<actual_result>[^"]+) is "(?<expected_result>[^"]+)", Domain Group "(?<child_name>[^"]+)" does not exist as child of Domain Group "(?<parent_name>[^"]+)"$/,
         %{actual_result: actual_result, expected_result: expected_result, child_name: child_name, parent_name: parent_name},
         _state do
    if actual_result == expected_result do
      token = get_user_token("app-admin")
      parent = get_domain_group_by_name(token, parent_name)
      child  = get_domain_group_by_name_and_parent(token, child_name, parent["id"])
      assert !child
    end
  end

  defand ~r/^if result (?<actual_result>[^"]+) is not "(?<expected_result>[^"]+)", Domain Group "(?<domain_group_name>[^"]+)" is a child of Domain Group "(?<parent_domain_group_name>[^"]+)"$/,
         %{actual_result: actual_result, expected_result: expected_result, domain_group_name: domain_group_name, parent_domain_group_name: parent_domain_group_name}, state do
    if actual_result != expected_result do
      domain_group_info = get_domain_group_by_name(state[:token_admin], domain_group_name)
      parent_domain_group_info = get_domain_group_by_name(state[:token_admin], parent_domain_group_name)
      assert domain_group_info["parent_id"] == parent_domain_group_info["id"]
    end
  end

  defwhen ~r/^user "(?<user_name>[^"]+)" tries to delete a Data Domain with the name "(?<data_domain_name>[^"]+)"$/,
          %{user_name: user_name, data_domain_name: data_domain_name}, state do

    token = get_user_token(user_name)
    data_domain_info = get_data_domain_by_name(token, data_domain_name)
    {:ok, status_code} = data_domain_delete(token, data_domain_info["id"])
    {:ok, Map.merge(state, %{status_code: status_code})}
  end

  defand ~r/^if result (?<actual_result>[^"]+) is "(?<expected_result>[^"]+)", Data Domain "(?<data_domain_name>[^"]+)" does not exist as child of Domain Group "(?<domain_group_name>[^"]+)"$/,
         %{actual_result: actual_result, expected_result: expected_result, data_domain_name: data_domain_name, domain_group_name: domain_group_name},
         _state do
    if actual_result == expected_result do
      token = get_user_token("app-admin")
      domain_group = get_domain_group_by_name(token, domain_group_name)
      data_domain  = get_data_domain_by_name_and_parent(token, data_domain_name, domain_group["id"])
      assert !data_domain
    end
  end

  defand ~r/^if result (?<actual_result>[^"]+) is not "(?<expected_result>[^"]+)", Data Domain "(?<data_domain_name>[^"]+)" is a child of Domain Group "(?<domain_group_name>[^"]+)"$/,
         %{actual_result: actual_result, expected_result: expected_result, data_domain_name: data_domain_name, domain_group_name: domain_group_name}, state do
    if actual_result != expected_result do
      domain_group_info = get_domain_group_by_name(state[:token_admin], domain_group_name)
      data_domain_info = get_data_domain_by_name(state[:token_admin], data_domain_name)
      assert data_domain_info["domain_group_id"] == domain_group_info["id"]
    end
  end

end
