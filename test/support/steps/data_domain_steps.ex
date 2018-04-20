defmodule TdBg.DataDomainSteps do
  @moduledoc false
  use Cabbage.Feature
  use ExUnit.CaseTemplate

  defgiven ~r/^an existing Data Domain called "(?<name>[^"]+)" child of Domain Group "(?<domain_group_name>[^"]+)"$/,
    %{name: name, domain_group_name: domain_group_name}, %{token_admin: token_admin} = _state do
      domain_group = get_domain_group_by_name(token_admin, domain_group_name)
      assert domain_group["name"] == domain_group_name
      {_, _status_code, json_resp} = data_domain_create(token_admin, %{name: name, domain_group_id: domain_group["id"]})
      data_domain = json_resp["data"]
      assert data_domain["domain_group_id"] == domain_group["id"]
  end

  defgiven ~r/^an existing Data Domain called "(?<name>[^"]+)" child of Domain Group "(?<domain_group_name>[^"]+)" with following data:$/,
         %{name: name, domain_group_name: domain_group_name, table: [%{Description: description}]}, state do
    domain_group_info = get_domain_group_by_name(state[:token_admin], domain_group_name)
    {:ok, _status_code, json_resp} = data_domain_create(state[:token_admin],  %{name: name, description: description, domain_group_id: domain_group_info["id"]})
    assert json_resp["data"]["domain_group_id"] == domain_group_info["id"]
    {:ok, state}
  end

  #Check if this step an be unified with other similar
  defgiven ~r/^an existing Data Domain called "(?<data_domain_name>[^"]+)" child of "(?<domain_group_name>[^"]+)"$/,
    %{data_domain_name: data_domain_name, domain_group_name: domain_group_name}, state do
    token_admin = build_user_token("app-admin", is_admin: true)
    domain_group = get_domain_group_by_name(token_admin, domain_group_name)
    assert domain_group && domain_group["id"]
    {_, _status_code, json_resp} = data_domain_create(token_admin, %{name: data_domain_name, description: "", domain_group_id: domain_group["id"]})
    data_domain = json_resp["data"]
    assert data_domain["domain_group_id"] == domain_group["id"]

    state = Map.merge(state, %{token_admin: token_admin})
    {:ok, state}
  end

  defwhen ~r/^user "(?<user_name>[^"]+)" tries to create a Data Domain with the name "(?<data_domain_name>[^"]+)" as child of Domain Group "(?<domain_group_name>[^"]+)" with following data:$/,
    %{user_name: user_name, data_domain_name: data_domain_name, domain_group_name: domain_group_name, table: [%{Description: description}]},
    %{token_admin: token_admin} = state do

    parent = get_domain_group_by_name(token_admin, domain_group_name)
    assert parent["name"] == domain_group_name
    token = build_user_token(user_name)
    {_, status_code, _json_resp} = data_domain_create(token, %{name: data_domain_name, description: description, domain_group_id: parent["id"]})
    {:ok, Map.merge(state, %{status_code: status_code})}
  end

end
