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

  defand ~r/^application locale is "(?<locale>[^"]+)"$/, %{locale: locale}, state do
    {:ok, Map.merge(state, %{locale: locale})}
  end

  defwhen ~r/^user "(?<user_name>[^"]+)" tries to create a Data Domain as child of Domain Group "(?<domain_group_name>[^"]+)" with following data:$/,
    %{user_name: user_name, domain_group_name: domain_group_name, table: [%{name: name, description: description}]}, state do

    parent = get_domain_group_by_name(state[:token_admin], domain_group_name)
    assert parent["name"] == domain_group_name
    token = build_user_token(user_name)
    {_, status_code, json_resp} = data_domain_create(token, %{name: name, description: description, domain_group_id: parent["id"]}, state[:locale])
    {:ok, Map.merge(state, %{status_code: status_code, data_domain_resp: json_resp})}
  end

  defthen ~r/^the system returns a result with code "(?<status_code>[^"]+)"$/,
          %{status_code: status_code}, %{status_code: http_status_code} = state do
    assert status_code == to_response_code(http_status_code)
    {:ok, Map.merge(state, %{})}
  end

  defand ~r/^the system returns a response with following data:$/,
    %{doc_string: json_string}, state do
    # Your implementation here
    actual_data = state[:data_domain_resp]
    expected_data = json_string |> JSON.decode!
    assert JSONDiff.diff(actual_data, expected_data) == []
  end

end
