defmodule TrueBG.SuperAdminTaxonomyTest do
  use Cabbage.Feature, async: false, file: "super_admin_taxonomy.feature"
  use TrueBGWeb.ConnCase
  import TrueBGWeb.Router.Helpers
  alias Poison, as: JSON
  alias TrueBG.Taxonomies
  @endpoint TrueBGWeb.Endpoint
  @headers {"Content-type", "application/json"}

  # Scenario: Creating a Domain Group without any parent

  defgiven ~r/^user "app-admin" is logged in the application$/, %{}, state do
    {_, status_code, json_resp} = session_create("app-admin", "mypass")
    assert "Created" == get_status(status_code)
    {:ok, Map.merge(state, %{status_code: status_code, token: json_resp["token"], resp: json_resp})}
  end

  defwhen ~r/^user "app-admin" tries to create a Domain Group with the name "(?<name>[^"]+)" and following data:$/, %{name: name, table: [%{Description: description}]}, state do
    {_, status_code, json_resp} = domain_group_create(state[:token], name, description)
    {:ok, Map.merge(state, %{status_code: status_code,  resp: json_resp})}
  end

  defthen ~r/^the system returns a result with code "(?<status_code>[^"]+)"$/, %{status_code: status_code}, state do
    assert status_code == get_status(state[:status_code])
  end

  defand ~r/^the user "app-admin" is able to see the Domain Group "(?<name>[^"]+)" with following data:$/, %{name: name, table: [%{Description: description}]}, state do
    id = state[:resp]["data"]["id"]
    temporal = domain_group_show(state[:token], id)
    {_, status_code, json_resp} = temporal
    assert "Ok" == get_status(status_code)
    assert name == json_resp["data"]["name"]
    assert description == json_resp["data"]["description"]
  end

  #Scenario
  defgiven ~r/^an existing Domain Group called "(?<name>[^"]+)"$/, %{name: name}, state do
    domain_group = Taxonomies.get_domain_group_by_name(name)
    unless domain_group do
      Taxonomies.create_domain_group(%{name: name})
    end
    {:ok, state}
  end

  defwhen ~r/^user "app-admin" tries to create a Domain Group with the name "(?<name>[^"]+)" as child of Domain Group "(?<parent_name>[^"]+)" with following data:$/,
          %{name: name, parent_name: parent_name, table: [%{Description: description}]}, state do

    {_, status_code, json_resp} = domain_group_create(state[:token], name, description, parent_name)
    {:ok, Map.merge(state, %{status_code: status_code,  resp: json_resp})}

  end

  defp session_create(user_name, user_password) do
    body = %{user: %{user_name: user_name, password: user_password}} |> JSON.encode!
    %HTTPoison.Response{status_code: status_code, body: resp} =
        HTTPoison.post!(session_url(@endpoint, :create), body, [@headers], [])
    {:ok, status_code, resp |> JSON.decode!}
  end

  defp domain_group_create(token, name, description, parent \\ nil) do
    headers = [@headers, {"authorization", "Bearer #{token}"}]
    body = %{domain_group: %{name: name, description: description, parent: parent}} |> JSON.encode!
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

  defp get_status(status_code) do
    case status_code do
      200 -> "Ok"
      201 -> "Created"
      401 -> "Forbidden"
      _ -> "Unknown"
    end
  end
end
