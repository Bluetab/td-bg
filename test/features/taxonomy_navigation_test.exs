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

  defp root_domain_group_list(token) do
    headers = get_header(token)
    %HTTPoison.Response{status_code: status_code, body: resp} =
      HTTPoison.get!(domain_group_url(@endpoint, :index_root), headers, [])
    {:ok, status_code, resp |> JSON.decode!}
  end

end
