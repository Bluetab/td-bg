defmodule TdBg.TaxonomyNavigationTest do
  use Cabbage.Feature, async: false, file: "taxonomy_navigation.feature"
  use TdBgWeb.FeatureCase
  import TdBgWeb.Router.Helpers
  import TdBgWeb.ResponseCode
  import TdBgWeb.Taxonomy
  import TdBgWeb.BusinessConcept
  import TdBgWeb.Authentication, only: :functions
  alias TdBgWeb.ApiServices.MockTdAuthService
  alias Poison, as: JSON
  @endpoint TdBgWeb.Endpoint

  @bc_fixed_fields %{"Description" => "description", "Name" => "name", "Type" => "type"}

  setup_all do
    start_supervised MockTdAuthService
    :ok
  end

  setup do
    on_exit fn ->
              rm_business_concept_schema()
            end
  end

  defand ~r/^an existing Domain Group called "(?<domain_group_name>[^"]+)" with following data:$/,
         %{domain_group_name: name, table: [%{Description: description}]}, state do

    token_admin = build_user_token("app-admin", is_admin: true)
    state = Map.merge(state, %{token_admin: token_admin})
    {:ok, status_code, json_resp} = domain_group_create(token_admin,  %{name: name, description: description})
    assert rc_created() == to_response_code(status_code)
    domain_group = json_resp["data"]
    assert domain_group["description"] == description
    {:ok, state}
  end

  defwhen ~r/^user "(?<user_name>[^"]+)" tries to query a list of all Domain Groups without parent$/, %{user_name: user_name}, state do
    # Your implementation here
    token = get_user_token(user_name)
    {:ok, status_code, json_resp} = root_domain_group_list(token)
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

  defthen ~r/^user sees following business concepts list:$/, %{table: table}, state do
    bc_list = state[:resp]["data"]
    bc_list = Enum.map(bc_list, &(Map.take(&1, ["name", "type", "status", "description"])))
    bc_list = Enum.reduce(bc_list, [], fn(item, acc) ->
      nitem = Map.new(item, fn {k, v} -> {String.to_atom(k), v} end)
      acc ++ [nitem]
      end
    )
    assert Enum.sort(table) == Enum.sort(bc_list)
  end

  #Scenario
  defand ~r/^an existing Domain Group called "(?<domain_group_name>[^"]+)"$/,
         %{domain_group_name: name}, state do
    token_admin = build_user_token("app-admin", is_admin: true)
    state = Map.merge(state, %{token_admin: token_admin})
    {:ok, status_code, _json_resp} = domain_group_create(state[:token_admin],  %{name: name})
    assert rc_created() == to_response_code(status_code)
    {:ok, state}
  end

  defand ~r/^an existing Domain Group called "(?<name>[^"]+)" child of Domain Group "(?<domain_group_name>[^"]+)"$/,
         %{name: name, domain_group_name: domain_group_name}, state do
    domain_group_info = get_domain_group_by_name(state[:token_admin], domain_group_name)
    assert domain_group_info["name"] == domain_group_name
    {:ok, status_code, json_resp} = domain_group_create(state[:token_admin],  %{name: name, parent_id: domain_group_info["id"]})
    assert rc_created() == to_response_code(status_code)
    assert json_resp["data"]["parent_id"] == domain_group_info["id"]
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

  defand ~r/^an existing Data Domain called "(?<name>[^"]+)" child of Domain Group "(?<domain_group_name>[^"]+)"$/,
          %{name: name, domain_group_name: domain_group_name}, %{token_admin: token_admin} = _state do
    domain_group = get_domain_group_by_name(token_admin, domain_group_name)
    assert domain_group["name"] == domain_group_name
    {_, _status_code, json_resp} = data_domain_create(token_admin, %{name: name, domain_group_id: domain_group["id"]})
    data_domain = json_resp["data"]
    assert data_domain["domain_group_id"] == domain_group["id"]
  end

  defand ~r/^an existing Business Concept type called "(?<business_concept_type>[^"]+)" with empty definition$/,
    %{business_concept_type: business_concept_type}, state do
      add_to_business_concept_schema(business_concept_type, [])
    {:ok, Map.merge(state, %{bc_type: business_concept_type})}
  end

  defand ~r/^an existing Business Concept of type "(?<business_concept_type>[^"]+)" in the Data Domain "(?<data_domain_name>[^"]+)" with following data:$/,
    %{business_concept_type: _business_concept_type, data_domain_name: data_domain_name,  table: fields},
    %{token_admin: token_admin} = state do
      attrs = field_value_to_api_attrs(fields, @bc_fixed_fields)
      data_domain = get_data_domain_by_name(token_admin, data_domain_name)
      business_concept_create(token_admin, data_domain["id"], attrs)
    {:ok, Map.merge(state, %{})}
  end

  defwhen ~r/^user "(?<user_name>[^"]+)" tries to query a list of all Domain Groups children of Domain Group "(?<domain_group_name>[^"]+)"$/,
    %{user_name: user_name, domain_group_name: domain_group_name}, state do
    token = get_user_token(user_name)
    domain_group_info = get_domain_group_by_name(state[:token_admin], domain_group_name)
    {:ok, status_code, json_resp} = index_domain_group_children(token, %{domain_group_id: domain_group_info["id"]})
    assert rc_ok() == to_response_code(status_code)
    {:ok, Map.merge(state, %{resp: json_resp})}
  end

  # Scenario

  defand ~r/^an existing Data Domain called "(?<name>[^"]+)" child of Domain Group "(?<domain_group_name>[^"]+)" with following data:$/,
         %{name: name, domain_group_name: domain_group_name, table: [%{Description: description}]}, state do
    domain_group_info = get_domain_group_by_name(state[:token_admin], domain_group_name)
    {:ok, _status_code, json_resp} = data_domain_create(state[:token_admin],  %{name: name, description: description, domain_group_id: domain_group_info["id"]})
    assert json_resp["data"]["domain_group_id"] == domain_group_info["id"]
    {:ok, state}
  end

  defwhen ~r/^user "(?<user_name>[^"]+)" tries to query a list of all Data Domains children of Domain Group "(?<domain_group_name>[^"]+)"$/,
    %{user_name: user_name, domain_group_name: domain_group_name}, state do
    token = get_user_token(user_name)
    domain_group_info = get_domain_group_by_name(state[:token_admin], domain_group_name)
    {:ok, status_code, json_resp} = index_domain_group_children_data_domain(token , %{domain_group_id: domain_group_info["id"]})
    assert rc_ok() == to_response_code(status_code)
    {:ok, Map.merge(state, %{resp: json_resp})}
  end

  defwhen ~r/^user "(?<user_name>[^"]+)" tries to query a list of all Business Concepts children of Data Domain "(?<data_domain_name>[^"]+)"$/,
    %{user_name: user_name, data_domain_name: data_domain_name}, state do
    token = get_user_token(user_name)
    data_domain_info = get_data_domain_by_name(state[:token_admin], data_domain_name)
    {:ok, status_code, json_resp} = index_data_domain_children_business_concept(token, %{data_domain_id: data_domain_info["id"]})
    assert rc_ok() == to_response_code(status_code)
    {:ok, Map.merge(state, %{resp: json_resp})}
  end

  defwhen ~r/^user "(?<user_name>[^"]+)" tries to list taxonomy tree"$/, %{user_name: user_name}, state do
    token = get_user_token(user_name)
    {:ok, 200, taxonomy_structure} = get_tree(token)
    {:ok, Map.merge(state, %{taxonomy_tree: taxonomy_structure["data"]})}
  end

  defthen ~r/^user sees following tree structure:$/,
    %{doc_string: json_string},
    state do
    actual_tree = state[:taxonomy_tree]
    expected_tree = json_string |> JSON.decode!

    #remove id and parent_id from comparison
    actual_tree = remove_tree_keys(actual_tree)
    assert JSONDiff.diff(actual_tree, expected_tree) == []
  end

  defp get_tree(token) do
    headers = get_header(token)
    %HTTPoison.Response{status_code: status_code, body: resp} =
      HTTPoison.get!(taxonomy_url(@endpoint, :tree), headers, [])
    {:ok, status_code, resp |> JSON.decode!}
  end

  defp index_domain_group_children_data_domain(token, attrs) do
    headers = get_header(token)
    id = attrs[:domain_group_id]
    %HTTPoison.Response{status_code: status_code, body: resp} =
      HTTPoison.get!(domain_group_data_domain_url(@endpoint, :index_children_data_domain, id), headers, [])
    {:ok, status_code, resp |> JSON.decode!}
  end

  defp index_data_domain_children_business_concept(token, attrs) do
    headers = get_header(token)
    id = attrs[:data_domain_id]
    %HTTPoison.Response{status_code: status_code, body: resp} =
      HTTPoison.get!(data_domain_business_concept_url(@endpoint, :index_children_business_concept, id), headers, [])
    {:ok, status_code, resp |> JSON.decode!}
  end

  defp index_domain_group_children(token, attrs) do
    headers = get_header(token)
    id = attrs[:domain_group_id]
    %HTTPoison.Response{status_code: status_code, body: resp} =
      HTTPoison.get!(domain_group_domain_group_url(@endpoint, :index_children, id), headers, [])
    {:ok, status_code, resp |> JSON.decode!}
  end

  defp root_domain_group_list(token) do
    headers = get_header(token)
    %HTTPoison.Response{status_code: status_code, body: resp} =
      HTTPoison.get!(domain_group_url(@endpoint, :index_root), headers, [])
    {:ok, status_code, resp |> JSON.decode!}
  end

  defp field_value_to_api_attrs(table, fixed_values) do
    table
      |> Enum.reduce(%{}, fn(x, acc) -> Map.put(acc, Map.get(fixed_values, x."Field", x."Field"), x."Value") end)
      |> Map.split(Map.values(fixed_values))
      |> fn({f, v}) -> Map.put(f, "content", v) end.()
  end

end
