defmodule TdBg.BusinessConcept.Search do
  @moduledoc """
  Helper module to construct business concept search queries.
  """
  alias TdBg.Auth.Claims
  alias TdBg.BusinessConcepts.Search.QueryBuilder
  alias TdBg.Permissions
  alias TdBg.Search
  alias TdBg.Search.Aggregations

  def get_filter_values(%Claims{} = claims, params) do
    opts = builder_opts(params)

    query =
      claims
      |> Permissions.get_search_permissions()
      |> QueryBuilder.build_filters(opts)
      |> QueryBuilder.build_query(params)

    search = %{query: query, aggs: Aggregations.aggregation_terms(), size: 0}
    Search.get_filters(search)
  end

  def search_business_concept_versions(params, claims, page \\ 0, size \\ 50)

  def search_business_concept_versions(params, %Claims{} = claims, page, size) do
    opts = builder_opts(params)

    query =
      claims
      |> Permissions.get_search_permissions()
      |> QueryBuilder.build_filters(opts)
      |> QueryBuilder.build_query(params)

    sort = Map.get(params, "sort", ["_score", "name.raw"])

    %{from: page * size, size: size, query: query, sort: sort}
    |> do_search()
  end

  defp builder_opts(%{} = params) do
    case params do
      %{"only_linkable" => true} -> [linkable: true]
      _ -> []
    end
  end

  def count(query) do
    %{query: query, size: 0}
    |> do_search()
    |> Map.get(:total)
  end

  defp do_search(search) do
    case Search.search(search) do
      %{results: results, total: total} ->
        %{results: Enum.map(results, &Map.get(&1, "_source", %{})), total: total}
    end
  end
end
