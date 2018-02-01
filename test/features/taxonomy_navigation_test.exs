defmodule TrueBG.TaxonomyNavigationTest do
  use Cabbage.Feature, async: false, file: "taxonomy_navigation.feature"
  use TrueBGWeb.ConnCase
  import TrueBGWeb.Router.Helpers
  import TrueBGWeb.ResponseCode
  import TrueBGWeb.Taxonomy
  import TrueBGWeb.Authentication, only: :functions
  alias Poison, as: JSON
  @endpoint TrueBGWeb.Endpoint

  defand ~r/^an existing Domain Group called "(?<domain_group_name>[^"]+)" with following data:$/,
         %{domain_group_name: name, table: [%{Description: description}]}, state do

    {:ok, status_code, json_resp} = session_create("app-admin", "mypass")
    assert rc_created() == to_response_code(status_code)
    state = Map.merge(state, %{status_code: status_code, token_admin: json_resp["token"], resp: json_resp})
    {:ok, status_code, json_resp} = domain_group_create(state[:token_admin],  %{name: name, description: description})
    assert rc_created() == to_response_code(status_code)
    domain_group = json_resp["data"]
    assert domain_group["description"] == description
    {:ok, state}
  end

  defand ~r/^user "(?<user_name>[^"]+)" is logged in the application with password "(?<password>[^"]+)"$/, %{user_name: user_name, password: password}, state do
    {_, status_code, json_resp} = session_create(user_name, password)
    assert rc_created() == to_response_code(status_code)
    {:ok, Map.merge(state, %{status_code: status_code, token: json_resp["token"], resp: json_resp})}
  end

  defwhen ~r/^user tries to query a list of all Domain Groups without parent$/, _vars, state do
    # Your implementation here
    {:ok, status_code, json_resp} = root_domain_group_list(state[:token])
    assert rc_ok() == to_response_code(status_code)
    {:ok, Map.merge(state, %{resp: json_resp})}
  end

  defthen ~r/^user sees following list:$/, %{table: table}, state do
    dg_list = state[:resp]["data"]
    dg_list = Enum.map(dg_list, &(Map.take(&1, ["name", "description"])))
    dg_list = Enum.reduce(dg_list, [], fn(item, acc) ->
      nitem = Map.new(item, fn {k, v} -> {String.to_atom(k), v} end)
      acc ++ [nitem]
      end
    )
    assert Enum.sort(table) == Enum.sort(dg_list)
  end

  #Scenario
  defand ~r/^an existing Domain Group called "(?<domain_group_name>[^"]+)"$/,
         %{domain_group_name: name}, state do

    {:ok, status_code, json_resp} = session_create("app-admin", "mypass")
    assert rc_created() == to_response_code(status_code)
    state = Map.merge(state, %{status_code: status_code, token_admin: json_resp["token"], resp: json_resp})
    {:ok, status_code, _json_resp} = domain_group_create(state[:token_admin],  %{name: name})
    assert rc_created() == to_response_code(status_code)
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

  defwhen ~r/^user tries to query a list of all Domain Groups children of Domain Group "(?<domain_group_name>[^"]+)"$/, %{domain_group_name: domain_group_name}, state do
    domain_group_info = get_domain_group_by_name(state[:token_admin], domain_group_name)
    {:ok, status_code, json_resp} = index_domain_group_children(state[:token], %{domain_group_id: domain_group_info["id"]})
    assert rc_ok() == to_response_code(status_code)
    {:ok, Map.merge(state, %{resp: json_resp})}
  end

  defp index_domain_group_children(token, attrs) do
    headers = get_header(token)
    id = attrs[:domain_group_id]
    %HTTPoison.Response{status_code: status_code, body: resp} =
      HTTPoison.get!(domain_group_url(@endpoint, :index_children, id), headers, [])
    {:ok, status_code, resp |> JSON.decode!}
  end

  defp root_domain_group_list(token) do
    headers = get_header(token)
    %HTTPoison.Response{status_code: status_code, body: resp} =
      HTTPoison.get!(domain_group_url(@endpoint, :index_root), headers, [])
    {:ok, status_code, resp |> JSON.decode!}
  end

end
