defmodule TdBg.TaxonomyNavigationTest do
  use Cabbage.Feature, async: false, file: "taxonomies/taxonomy_navigation.feature"
  use TdBgWeb.FeatureCase
  import TdBgWeb.Router.Helpers
  import TdBgWeb.ResponseCode
  import TdBgWeb.Taxonomy
  import TdBgWeb.BusinessConcept
  import TdBgWeb.Authentication, only: :functions
  alias TdBgWeb.ApiServices.MockTdAuthService
  alias Poison, as: JSON
  @endpoint TdBgWeb.Endpoint

  import_steps TdBg.BusinessConceptSteps
  import_steps TdBg.DomainSteps

  import TdBg.BusinessConceptSteps

  setup_all do
    start_supervised MockTdAuthService
    :ok
  end

  setup do
    on_exit fn ->
              rm_business_concept_schema()
            end
  end

  defwhen ~r/^user "(?<user_name>[^"]+)" tries to query a list of all Domains without parent$/, %{user_name: user_name}, state do
    # Your implementation here
    token = get_user_token(user_name)
    {:ok, status_code, json_resp} = root_domain_list(token)
    assert rc_ok() == to_response_code(status_code)
    {:ok, Map.merge(state, %{resp: json_resp})}
  end

  defthen ~r/^user sees following list:$/, %{table: table}, state do
    dg_list = state[:resp]["data"]["collection"]
    dg_list = Enum.map(dg_list, &(Map.take(&1, ["name", "description"])))
    dg_list = Enum.reduce(dg_list, [], fn(item, acc) ->
      nitem = Map.new(item, fn {k, v} -> {String.to_atom(k), v} end)
      acc ++ [nitem]
      end
    )
    assert Enum.sort(table) == Enum.sort(dg_list)
  end

  defthen ~r/^user sees following business concepts list:$/, %{table: table}, state do
    bc_list = state[:resp]["data"]["collection"]
    bc_list = Enum.map(bc_list, &(Map.take(&1, ["name", "type", "status", "description"])))
    bc_list = Enum.reduce(bc_list, [], fn(item, acc) ->
      nitem = Map.new(item, fn {k, v} -> {String.to_atom(k), v} end)
      acc ++ [nitem]
      end
    )
    assert Enum.sort(table) == Enum.sort(bc_list)
  end

  defwhen ~r/^user "(?<user_name>[^"]+)" tries to query a list of all Domains children of Domain "(?<domain_name>[^"]+)"$/,
    %{user_name: user_name, domain_name: domain_name}, state do
    token = get_user_token(user_name)
    domain_info = get_domain_by_name(state[:token_admin], domain_name)
    {:ok, status_code, json_resp} = index_domain_children(token, %{domain_id: domain_info["id"]})
    assert rc_ok() == to_response_code(status_code)
    {:ok, Map.merge(state, %{resp: json_resp})}
  end

  # defwhen ~r/^user "(?<user_name>[^"]+)" tries to query a list of all Data Domains children of Domain "(?<domain_name>[^"]+)"$/,
  #   %{user_name: user_name, domain_name: domain_name}, state do
  #   token = get_user_token(user_name)
  #   domain_info = get_domain_by_name(state[:token_admin], domain_name)
  #   {:ok, status_code, json_resp} = index_domain_group_children_data_domain(token , %{domain_group_id: domain_info["id"]})
  #   assert rc_ok() == to_response_code(status_code)
  #   {:ok, Map.merge(state, %{resp: json_resp})}
  # end

  defwhen ~r/^user "(?<user_name>[^"]+)" tries to query a list of all Business Concepts children of Domain "(?<domain_name>[^"]+)"$/,
    %{user_name: user_name, domain_name: domain_name}, state do
    token = get_user_token(user_name)
    domain_info = get_domain_by_name(state[:token_admin], domain_name)
    {:ok, status_code, json_resp} = index_domain_children_business_concept(token, %{domain_id: domain_info["id"]})
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

  defp index_domain_children_business_concept(token, attrs) do
    headers = get_header(token)
    id = attrs[:domain_id]
    %HTTPoison.Response{status_code: status_code, body: resp} =
      HTTPoison.get!(business_concept_url(@endpoint, :index_children_business_concept, id), headers, [])
    {:ok, status_code, resp |> JSON.decode!}
  end

  defp index_domain_children(token, attrs) do
    headers = get_header(token)
    id = attrs[:domain_id]
    %HTTPoison.Response{status_code: status_code, body: resp} =
      HTTPoison.get!(domain_domain_url(@endpoint, :index_children, id), headers, [])
    {:ok, status_code, resp |> JSON.decode!}
  end

  defp root_domain_list(token) do
    headers = get_header(token)
    %HTTPoison.Response{status_code: status_code, body: resp} =
      HTTPoison.get!(domain_url(@endpoint, :index_root), headers, [])
    {:ok, status_code, resp |> JSON.decode!}
  end

end
