defmodule TrueBG.SuperAdminTaxonomyTest do
  use Cabbage.Feature, async: false, file: "super_admin_taxonomy.feature"
  use TrueBGWeb.ConnCase
  import TrueBGWeb.Taxonomy, only: :functions
  import TrueBGWeb.Authentication, only: :functions
  import TrueBGWeb.ResponseCode, only: :functions

  # Scenario: Creating a Domain Group without any parent

  defgiven ~r/^an existing Domain Group called "(?<domain_group_name>[^"]+)"$/,
    %{domain_group_name: domain_group_name}, _state do
    token = get_user_token("app-admin")
    {_, status_code, _json_resp} = domain_group_create(token, %{name: domain_group_name})
    assert rc_created() == to_response_code(status_code)
  end

  defwhen ~r/^user "app-admin" tries to create a Domain Group with the name "(?<name>[^"]+)" and following data:$/, %{name: name, table: [%{Description: description}]}, state do
    token = get_user_token("app-admin")
    {_, status_code, _json_resp} = domain_group_create(token,  %{name: name, description: description})
    {:ok, Map.merge(state, %{status_code: status_code})}
  end

  defthen ~r/^the system returns a result with code "(?<status_code>[^"]+)"$/,
          %{status_code: status_code}, %{status_code: http_status_code} = state do
    assert status_code == to_response_code(http_status_code)
    {:ok, Map.merge(state, %{})}
  end

  defand ~r/^the user "app-admin" is able to see the Domain Group "(?<domain_group_name>[^"]+)" with following data:$/,
    %{domain_group_name: domain_group_name, table: [%{Description: description}]}, _state do
      token = get_user_token("app-admin")
      domain_group =  get_domain_group_by_name(token, domain_group_name)
      {_, status_code, json_resp} = domain_group_show(token, domain_group["id"])
      assert rc_ok() == to_response_code(status_code)
      domain_group = json_resp["data"]
      assert domain_group["description"] == description
      assert domain_group["name"] == domain_group_name
  end

  #Scenario Creating a Domain Group as child of an existing Domain Group
  defwhen ~r/^user "app-admin" tries to create a Domain Group with the name "(?<name>[^"]+)" as child of Domain Group "(?<parent_name>[^"]+)" with following data:$/,
          %{name: name, parent_name: parent_name, table: [%{Description: description}]}, state do
    token = get_user_token("app-admin")
    parent = get_domain_group_by_name(token, parent_name)
    assert parent["name"] == parent_name
    {_, status_code, _json_resp} = domain_group_create(token, %{name: name, description: description, parent_id: parent["id"]})
    {:ok, Map.merge(state, %{status_code: status_code})}
  end

  defand ~r/^Domain Group "(?<name>[^"]+)" is a child of Domain Group "(?<parent_name>[^"]+)"$/, %{name: name, parent_name: parent_name}, _state do
    token = get_user_token("app-admin")
    child = get_domain_group_by_name(token, name)
    parent = get_domain_group_by_name(token, parent_name)
    assert child["name"] == name
    assert parent["name"] == parent_name
    assert child["parent_id"] == parent["id"]
  end

  # Scenario: Creating a Data Domain depending on an existing Domain Group
  defwhen ~r/^user "(?<user_name>[^"]+)" tries to create a Data Domain with the name "(?<data_domain_name>[^"]+)" as child of Domain Group "(?<domain_group_name>[^"]+)" with following data:$/,
          %{user_name: _user_name, data_domain_name: data_domain_name, domain_group_name: domain_group_name, table: [%{Description: description}]}, state do
    token = get_user_token("app-admin")
    parent = get_domain_group_by_name(token, domain_group_name)
    assert parent["name"] == domain_group_name
    {_, status_code, _json_resp} = data_domain_create(token, %{name: data_domain_name, description: description, domain_group_id: parent["id"]})
    {:ok, Map.merge(state, %{status_code: status_code})}
  end

  defand ~r/^the user "(?<user_name>[^"]+)" is able to see the Data Domain "(?<data_domain_name>[^"]+)" with following data:$/,
         %{user_name: _user_name, data_domain_name: data_domain_name, table: [%{Description: description}]}, state do
    token = get_user_token("app-admin")
    data_domain_info = get_data_domain_by_name(token, data_domain_name)
    assert data_domain_name == data_domain_info["name"]
    {_, status_code, json_resp} = data_domain_show(token, data_domain_info["id"])
    assert rc_ok() == to_response_code(status_code)
    data_domain = json_resp["data"]
    assert data_domain_name == data_domain["name"]
    assert description == data_domain["description"]
    {:ok, %{state | status_code: nil}}
  end

  defand ~r/^Data Domain "(?<data_domain_name>[^"]+)" is a child of Domain Group "(?<domain_group_name>[^"]+)"$/,
          %{data_domain_name: data_domain_name, domain_group_name: domain_group_name}, _state do
    token = get_user_token("app-admin")
    data_domain_info = get_data_domain_by_name(token, data_domain_name)
    assert data_domain_name == data_domain_info["name"]
    domain_group_info = get_domain_group_by_name(token, domain_group_name)
    assert domain_group_name == domain_group_info["name"]
    assert data_domain_info["domain_group_id"] == domain_group_info["id"]
  end

  defand ~r/^an existing Data Domain called "(?<name>[^"]+)" child of Domain Group "(?<domain_group_name>[^"]+)"$/,
      %{name: name, domain_group_name: domain_group_name}, _state do
    token = get_user_token("app-admin")
    domain_group_info = get_domain_group_by_name(token, domain_group_name)
    assert domain_group_info["name"] == domain_group_name
    {_, _status_code, json_resp} = data_domain_create(token, %{name: name, domain_group_id: domain_group_info["id"]})
    data_domain = json_resp["data"]
    assert data_domain["domain_group_id"] == domain_group_info["id"]
  end

  # Scenario: Modifying a Domain Group and seeing the new version
  defgiven ~r/^an existing Domain Group called "(?<domain_group_name>[^"]+)" with following data:$/,
        %{domain_group_name: domain_group_name, table: [%{Description: description}]}, _state do
    token = get_user_token("app-admin")
    {_, _status_code, json_resp} = domain_group_create(token, %{name: domain_group_name, description: description})
    domain_group = json_resp["data"]
    assert domain_group["description"] == description
  end

  defand ~r/^user "app-admin" tries to modify a Domain Group with the name "(?<domain_group_name>[^"]+)" introducing following data:$/,
      %{domain_group_name: domain_group_name, table: [%{Description: description}]}, state do
    token = get_user_token("app-admin")
    domain_group = get_domain_group_by_name(token, domain_group_name)
    {_, status_code, _json_resp} = domain_group_update(token, domain_group["id"], %{name: domain_group_name, description: description})
    {:ok, Map.merge(state, %{status_code: status_code})}
  end

  # Scenario: Modifying a Data Domain and seeing the new version
  defand ~r/^an existing Data Domain called "(?<data_domain_name>[^"]+)" child of Domain Group "(?<domain_group_name>[^"]+)" with following data:$/,
        %{data_domain_name: data_domain_name, domain_group_name: domain_group_name, table: [%{Description: description}]}, _state do
    token = get_user_token("app-admin")
    domain_group = get_domain_group_by_name(token, domain_group_name)
    assert domain_group && domain_group["id"]
    {_, _status_code, json_resp} = data_domain_create(token, %{name: data_domain_name, description: description, domain_group_id: domain_group["id"]})
    data_domain = json_resp["data"]
    assert data_domain["domain_group_id"] == domain_group["id"]
    assert data_domain["description"] == description
  end

  defwhen ~r/^user "app-admin" tries to modify a Data Domain with the name "(?<data_domain_name>[^"]+)" introducing following data:$/,
      %{data_domain_name: data_domain_name, table: [%{Description: description}]}, state do
    token = get_user_token("app-admin")
    data_domain_info = get_data_domain_by_name(token, data_domain_name)
    {:ok, status_code, _json_resp} = data_domain_update(token, data_domain_info["id"], %{name: data_domain_name, description: description})
    {:ok, Map.merge(state, %{status_code: status_code})}
  end

  defand ~r/^an existing Domain Group called "(?<child_name>[^"]+)" child of Domain Group "(?<parent_name>[^"]+)"$/,
    %{child_name: child_name, parent_name: parent_name},
    _state do
    token = get_user_token("app-admin")
    parent = get_domain_group_by_name(token, parent_name)
    {_, http_status_code, _json_resp} = domain_group_create(token, %{name: child_name, parent_id: parent["id"]})
    assert rc_created() == to_response_code(http_status_code)
  end

  defwhen ~r/^user "(?<user_name>[^"]+)" tries to delete a Domain Group with the name "(?<domain_group_name>[^"]+)"$/,
    %{user_name: user_name, domain_group_name: domain_group_name},
    state do
    token = get_user_token(user_name)
    domain_group = get_domain_group_by_name(token, domain_group_name)
    {_, status_code} = domain_group_delete(token, domain_group["id"])
    {:ok, Map.merge(state, %{status_code: status_code})}
  end

  defand ~r/^Domain Group "(?<child_name>[^"]+)" does not exist as child of Domain Group "(?<parent_name>[^"]+)"$/,
    %{child_name: child_name, parent_name: parent_name},
    _state do
      token = get_user_token("app-admin")
      parent = get_domain_group_by_name(token, parent_name)
      child  = get_domain_group_by_name_and_parent(token, child_name, parent["id"])
      assert !child
  end

  defand ~r/^Domain Group "(?<child_name>[^"]+)" exist as child of Domain Group "(?<parent_name>[^"]+)"$/,
    %{child_name: child_name, parent_name: parent_name},
    _state do
      token = get_user_token("app-admin")
      parent = get_domain_group_by_name(token, parent_name)
      child  = get_domain_group_by_name_and_parent(token, child_name, parent["id"])
      assert child
  end

end
