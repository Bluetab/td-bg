defmodule TdBg.TaxonomyErrorsTest do
  use Cabbage.Feature, async: false, file: "taxonomy_errors.feature"
  use TdBgWeb.FeatureCase
  import TdBgWeb.ResponseCode
  import TdBgWeb.Taxonomy
  import TdBgWeb.Authentication, only: :functions
  alias Poison, as: JSON
  alias TdBgWeb.ApiServices.MockTdAuthService

  setup_all do
    start_supervised MockTdAuthService
    :ok
  end

  defand ~r/^an existing Domain Group called "(?<domain_group_name>[^"]+)"$/,
         %{domain_group_name: name}, state do

    token_admin = build_user_token("app-admin", is_admin: true)
    state = Map.merge(state, %{token_admin: token_admin})
    {:ok, status_code, _json_resp} = domain_group_create(token_admin,  %{name: name})
    assert rc_created() == to_response_code(status_code)
    {:ok, state}
  end

  defwhen ~r/^user "(?<user_name>[^"]+)" tries to create a Data Domain as child of Domain Group "(?<domain_group_name>[^"]+)" with following data:$/,
    %{user_name: user_name, domain_group_name: domain_group_name, table: [%{name: name, description: description}]}, state do

    parent = get_domain_group_by_name(state[:token_admin], domain_group_name)
    assert parent["name"] == domain_group_name
    token = build_user_token(user_name)
    {_, status_code, json_resp} = data_domain_create(token, %{name: name, description: description, domain_group_id: parent["id"]})
    {:ok, Map.merge(state, %{status_code: status_code, json_resp: json_resp})}
  end

  defthen ~r/^the system returns a result with code "(?<status_code>[^"]+)"$/,
    %{status_code: status_code}, %{status_code: http_status_code} = state do
    assert status_code == to_response_code(http_status_code)
    {:ok, Map.merge(state, %{})}
  end

  defand ~r/^the system returns a response with following data:$/,
    %{doc_string: json_string}, state do
    # Your implementation here
    actual_data = state[:json_resp]
    expected_data = json_string |> JSON.decode!
    assert JSONDiff.diff(actual_data, expected_data) == []
  end

  defand ~r/^an existing Data Domain called "(?<data_domain_name>[^"]+)" child of "(?<domain_group_name>[^"]+)"$/,
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

  defwhen ~r/^user "(?<username>[^"]+)" tries to update a Data Domain called "(?<data_domain_name>[^"]+)" child of Domain Group "(?<domain_group_name>[^"]+)" with following data:$/,
    %{username: username, data_domain_name: data_domain_name, domain_group_name: domain_group_name, table: [%{name: name, description: description}]}, state do
    token_admin = build_user_token(username, is_admin: true)
    domain_group = get_domain_group_by_name(token_admin, domain_group_name)
    data_domain = get_data_domain_by_name_and_parent(token_admin, data_domain_name, domain_group["id"])
    {_, status_code, json_resp} = data_domain_update(token_admin, data_domain["id"], %{name: name, description: description})
    {:ok, Map.merge(state, %{token_admin: token_admin, status_code: status_code, json_resp: json_resp})}
  end

  defwhen ~r/^user "(?<username>[^"]+)" tries to create a Domain Group with following data:$/,
    %{username: username, table: [%{name: name, description: description}]},
    state do
    token_admin = build_user_token(username, is_admin: true)
    {_, status_code, json_resp} = domain_group_create(token_admin, %{name: name, description: description})
    {:ok, Map.merge(state, %{token_admin: token_admin, status_code: status_code, json_resp: json_resp})}
  end

end
