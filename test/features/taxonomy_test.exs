defmodule TdBg.TaxonomyTest do
  use Cabbage.Feature, async: false, file: "taxonomy.feature"
  use TdBgWeb.FeatureCase
  import TdBgWeb.BusinessConcept
  import TdBgWeb.ResponseCode
  import TdBgWeb.Taxonomy
  import TdBgWeb.User, only: :functions
  import TdBgWeb.Authentication, only: :functions
  import TdBgWeb.AclEntry, only: :functions

  alias TdBgWeb.ApiServices.MockTdAuthService

  import_steps TdBg.BusinessConceptSteps
  import_steps TdBg.DataDomainSteps
  import_steps TdBg.DomainGroupSteps
  import_steps TdBg.ResultSteps
  import_steps TdBg.UsersSteps

  import TdBg.ResultSteps
  import TdBg.BusinessConceptSteps
  import TdBg.UsersSteps

  setup_all do
    start_supervised MockTdAuthService
    :ok
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

  defand ~r/^user "(?<user_name>[^"]+)" tries to modify a Domain Group with the name "(?<domain_group_name>[^"]+)" introducing following data:$/,
    %{user_name: user_name, domain_group_name: domain_group_name, table: [%{Description: description}]}, state do
    token = get_user_token(user_name)
    domain_group = get_domain_group_by_name(token, domain_group_name)
    {_, status_code, _json_resp} = domain_group_update(token, domain_group["id"], %{name: domain_group_name, description: description})
    {:ok, Map.merge(state, %{status_code: status_code})}
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
