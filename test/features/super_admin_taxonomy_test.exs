defmodule TrueBG.SuperAdminTaxonomyTest do
  use Cabbage.Feature, async: false, file: "super_admin_taxonomy.feature"
  use TrueBGWeb.ConnCase
  import TrueBGWeb.Router.Helpers
  import TrueBGWeb.ResponseCode
  alias Poison, as: JSON
  alias TrueBG.Taxonomies
  @endpoint TrueBGWeb.Endpoint
  @headers {"Content-type", "application/json"}

  # Scenario: Creating a Domain Group without any parent

  defgiven ~r/^user "app-admin" is logged in the application$/, %{}, state do
    {_, status_code, json_resp} = session_create("app-admin", "mypass")
    assert rc_created() == to_response_code(status_code)
    {:ok, Map.merge(state, %{status_code: status_code, token: json_resp["token"], resp: json_resp})}
  end

  defwhen ~r/^user "app-admin" tries to create a Domain Group with the name "(?<name>[^"]+)" and following data:$/, %{name: name, table: [%{Description: description}]}, state do
    {_, status_code, json_resp} = domain_group_create(state[:token], name, description)
    {:ok, Map.merge(state, %{status_code: status_code,  resp: json_resp})}
  end

  defthen ~r/^the system returns a result with code "(?<status_code>[^"]+)"$/, %{status_code: status_code}, state do
    assert status_code == to_response_code(state[:status_code])
  end

  defand ~r/^the user "app-admin" is able to see the Domain Group "(?<name>[^"]+)" with following data:$/, %{name: name, table: [%{Description: description}]}, state do
    id = state[:resp]["data"]["id"]
    temporal = domain_group_show(state[:token], id)
    {_, status_code, json_resp} = temporal
    assert rc_ok() == to_response_code(status_code)
    assert name == json_resp["data"]["name"]
    assert description == json_resp["data"]["description"]
  end

  #Scenario
  defgiven ~r/^an existing Domain Group called "(?<name>[^"]+)"$/, %{name: name}, state do
    existing_dg = Taxonomies.get_domain_group_by_name(name)
    {_, domain_group} =
      if existing_dg == nil do
        Taxonomies.create_domain_group(%{name: name})
      else
        {:ok, existing_dg}
      end
    {:ok, Map.merge(state, %{domain_group: domain_group})}
  end

  defwhen ~r/^user "app-admin" tries to create a Domain Group with the name "(?<name>[^"]+)" as child of Domain Group "(?<parent_name>[^"]+)" with following data:$/,
          %{name: name, parent_name: parent_name, table: [%{Description: description}]}, state do

    parent = state[:domain_group]
    assert parent.name == parent_name

    {_, status_code, json_resp} = domain_group_create(state[:token], name, description, parent.id)
    {:ok, Map.merge(state, %{status_code: status_code,  resp: json_resp})}
  end

  defand ~r/^Domain Group "(?<name>[^"]+)" is a child of Domain Group "(?<parent_name>[^"]+)"$/, %{name: name, parent_name: parent_name}, state do
    parent = state[:domain_group]
    child = state[:resp]["data"]
    assert child["name"] == name
    assert parent.name == parent_name
    assert child["parent_id"] == parent.id
  end

  # Scenario: Creating a Data Domain depending on an existing Domain Group

  defwhen ~r/^user "(?<user_name>[^"]+)" tries to create a Data Domain with the name "(?<data_domain_name>[^"]+)" as child of Domain Group "(?<domain_group_name>[^"]+)" with following data:$/,
          %{user_name: _user_name, data_domain_name: data_domain_name, domain_group_name: domain_group_name, table: [%{Description: description}]}, state do

    parent = state[:domain_group]
    assert parent.name == domain_group_name
    {_, status_code, json_resp} = data_domain_create(state[:token], %{name: data_domain_name, description: description, domain_group_id: parent.id})
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
    assert domain_group_name == domain_group_info.name
    assert data_domain_info["domain_group_id"] == domain_group_info.id
  end

  defp session_create(user_name, user_password) do
    body = %{user: %{user_name: user_name, password: user_password}} |> JSON.encode!
    %HTTPoison.Response{status_code: status_code, body: resp} =
        HTTPoison.post!(session_url(@endpoint, :create), body, [@headers], [])
    {:ok, status_code, resp |> JSON.decode!}
  end

  defp domain_group_create(token, name, description, parent_id \\ nil) do
    headers = [@headers, {"authorization", "Bearer #{token}"}]
    body = %{domain_group: %{name: name, description: description, parent_id: parent_id}} |> JSON.encode!
    %HTTPoison.Response{status_code: status_code, body: resp} =
        HTTPoison.post!(domain_group_url(@endpoint, :create), body, headers, [])
    {:ok, status_code, resp |> JSON.decode!}
  end

  defp domain_group_show(token, id) do
    headers = [@headers, {"authorization", "Bearer #{token}"}]
    %HTTPoison.Response{status_code: status_code, body: resp} =
      HTTPoison.get!(domain_group_url(@endpoint, :show, id), headers, [])
    {:ok, status_code, resp |> JSON.decode!}
  end

  defp data_domain_create(token, data_domain_params) do
    headers = [@headers, {"authorization", "Bearer #{token}"}]
    body = %{data_domain: data_domain_params} |> JSON.encode!
    %HTTPoison.Response{status_code: status_code, body: resp} =
      HTTPoison.post!(data_domain_url(@endpoint, :create), body, headers, [])
    {:ok, status_code, resp |> JSON.decode!}
  end

  defp data_domain_show(token, id) do
    headers = [@headers, {"authorization", "Bearer #{token}"}]
    %HTTPoison.Response{status_code: status_code, body: resp} =
      HTTPoison.get!(data_domain_url(@endpoint, :show, id), headers, [])
    {:ok, status_code, resp |> JSON.decode!}
  end
end
