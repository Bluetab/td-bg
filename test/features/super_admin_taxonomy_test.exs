defmodule TrueBG.SuperAdminTaxonomyTest do
  use Cabbage.Feature, async: false, file: "super_admin_taxonomy.feature"
  use TrueBGWeb.ConnCase
  import TrueBGWeb.Taxonomy
  import TrueBGWeb.Authentication
  import TrueBGWeb.ResponseCode

  # Scenario: Creating a Domain Group without any parent
  defgiven ~r/^user "app-admin" is logged in the application$/, %{}, state do
    {_, status_code, json_resp} = session_create("app-admin", "mypass")
    assert rc_created() == to_response_code(status_code)
    {:ok, Map.merge(state, %{status_code: status_code, token: json_resp["token"]})}
  end

  defwhen ~r/^user "app-admin" tries to create a Domain Group with the name "(?<name>[^"]+)" and following data:$/, %{name: name, table: [%{Description: description}]}, state do
    {_, status_code, json_resp} = domain_group_create(state[:token], name, description)
    domain_group = json_resp["data"]
    {:ok, Map.merge(state, %{status_code: status_code,  domain_group: domain_group})}
  end

  defthen ~r/^the system returns a result with code "(?<status_code>[^"]+)"$/, %{status_code: status_code}, state do
    assert status_code == to_response_code(state[:status_code])
  end

  defand ~r/^the user "app-admin" is able to see the Domain Group "(?<domain_group_name>[^"]+)" with following data:$/,
    %{domain_group_name: domain_group_name, table: [%{Description: description}]}, state do
      token = state[:token]
      {_, _status_code, json_resp} = domain_group_list(token)
      domain_group =  getDomainGroupByName(json_resp["data"], domain_group_name)
      {_, status_code, json_resp} = domain_group_show(token, domain_group["id"])
      assert rc_ok() == to_response_code(status_code)
      domain_group = json_resp["data"]
      assert domain_group["description"] == description
  end

  #Scenario Creating a Domain Group as child of an existing Domain Group
  defgiven ~r/^an existing Domain Group called "(?<name>[^"]+)"$/, %{name: name}, state do
    {_, _status_code, json_resp} = domain_group_create(state[:token], name, "New Description")
    domain_group = json_resp["data"]
    {:ok, Map.merge(state, %{domain_group: domain_group})}
  end

  defwhen ~r/^user "app-admin" tries to create a Domain Group with the name "(?<name>[^"]+)" as child of Domain Group "(?<parent_name>[^"]+)" with following data:$/,
          %{name: name, parent_name: parent_name, table: [%{Description: description}]}, state do
    parent = state[:domain_group]
    assert parent["name"] == parent_name
    {_, status_code, json_resp} = domain_group_create(state[:token], name, description, parent["id"])
    domain_group = json_resp["data"]
    {:ok, Map.merge(state, %{status_code: status_code,  domain_group: domain_group})}
  end

  defand ~r/^Domain Group "(?<name>[^"]+)" is a child of Domain Group "(?<parent_name>[^"]+)"$/, %{name: name, parent_name: parent_name}, state do
    {_, _status_code, json_resp} = domain_group_list(state[:token])
    child = getDomainGroupByName(json_resp["data"], name)
    parent = getDomainGroupByName(json_resp["data"], parent_name)
    assert child["name"] == name
    assert parent["name"] == parent_name
    assert child["parent_id"] == parent["id"]
  end

  # Scenario: Creating a Data Domain depending on an existing Domain Group
  defwhen ~r/^user "(?<user_name>[^"]+)" tries to create a Data Domain with the name "(?<data_domain_name>[^"]+)" as child of Domain Group "(?<domain_group_name>[^"]+)" with following data:$/,
          %{user_name: _user_name, data_domain_name: data_domain_name, domain_group_name: domain_group_name, table: [%{Description: description}]}, state do

    parent = state[:domain_group]
    assert parent["name"] == domain_group_name
    {_, status_code, json_resp} = data_domain_create(state[:token], %{name: data_domain_name, description: description, domain_group_id: parent["id"]})
    {:ok, Map.merge(state, %{status_code: status_code,  resp: json_resp})}
  end

  defand ~r/^the user "(?<user_name>[^"]+)" is able to see the Data Domain "(?<data_domain_name>[^"]+)" with following data:$/,
         %{user_name: _user_name, data_domain_name: name, table: [%{Description: description}]}, state do
    data_domain_info = state[:resp]["data"]
    assert name == data_domain_info["name"]
    {_, status_code, json_resp} = data_domain_show(state[:token], data_domain_info["id"])
    assert rc_ok() == to_response_code(status_code)
    assert json_resp["data"]["name"]
    assert description == json_resp["data"]["description"]
    {:ok, %{state | status_code: nil}}
  end

  defand ~r/^Data Domain "(?<data_domain_name>[^"]+)" is a child of Domain Group "(?<domain_group_name>[^"]+)"$/, %{data_domain_name: data_domain_name, domain_group_name: domain_group_name}, state do
    data_domain_info = state[:resp]["data"]
    assert data_domain_name == data_domain_info["name"]
    domain_group_info = state[:domain_group]
    assert domain_group_name == domain_group_info["name"]
    assert data_domain_info["domain_group_id"] == domain_group_info["id"]
  end

  defand ~r/^an existing Data Domain called "(?<name>[^"]+)" child of Domain Group "(?<domain_group_name>[^"]+)"$/, %{name: name, domain_group_name: domain_group_name}, state do
    domain_group_info = state[:domain_group]
    assert domain_group_info["name"] == domain_group_name
    {_, _status_code, json_resp} = data_domain_create(state[:token], %{name: name, description: "New Description", domain_group_id: domain_group_info["id"]})
    data_domain = json_resp["data"]
    assert data_domain["domain_group_id"] == domain_group_info["id"]
    {:ok, Map.merge(state, %{data_domain: data_domain})}
  end

  # Scenario: Modifying a Domain Group and seeing the new version
  defand ~r/^an existing Domain Group called "(?<domain_group_name>[^"]+)" with following data:$/, %{domain_group_name: domain_group_name, table: [%{Description: description}]}, state do
    {_, _status_code, json_resp} = domain_group_create(state[:token], domain_group_name, description)
    domain_group = json_resp["data"]
    assert domain_group["description"] == description
    {:ok, Map.merge(state, %{domain_group: domain_group})}
  end

  defand ~r/^user "app-admin" tries to modify a Domain Group with the name "(?<domain_group_name>[^"]+)" introducing following data:$/, %{domain_group_name: domain_group_name, table: [%{Description: description}]}, state do
    domain_group = state[:domain_group]
    {_, status_code, json_resp} = domain_group_update(state[:token], domain_group["id"], domain_group_name, description)
    {:ok, Map.merge(state, %{status_code: status_code,  resp: json_resp})}
  end

  # Scenario: Modifying a Data Domain and seeing the new version
  defand ~r/^an existing Data Domain called "(?<data_domain_name>[^"]+)" child of Domain Group "(?<domain_group_name>[^"]+)" with following data:$/,
    %{data_domain_name: data_domain_name, domain_group_name: domain_group_name, table: [%{Description: description}]}, state do

    {_, _status_code, json_resp} = domain_group_create(state[:token], domain_group_name, "New Description")
    domain_group = json_resp["data"]
    {_, _status_code, json_resp} = data_domain_create(state[:token], %{name: data_domain_name, description: description, domain_group_id: domain_group["id"]})
    data_domain = json_resp["data"]
    assert data_domain["domain_group_id"] == domain_group["id"]
    assert data_domain["description"] == description
    {:ok, Map.merge(state, %{data_domain: data_domain})}
  end

  defwhen ~r/^user "app-admin" tries to modify a Data Domain with the name "(?<data_domain_name>[^"]+)" introducing following data:$/, %{data_domain_name: data_domain_name, table: [%{Description: description}]}, state do
    {_, status_code, json_resp} = data_domain_update(state[:token], state[:data_domain]["id"], data_domain_name, description)
    {:ok, Map.merge(state, %{status_code: status_code,  resp: json_resp})}
  end
end
