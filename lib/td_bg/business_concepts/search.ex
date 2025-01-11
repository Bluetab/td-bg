defmodule TdBg.BusinessConcept.Search do
  @moduledoc """
  Helper module to construct business concept search queries.
  """

  alias TdBg.Auth.Claims
  alias TdBg.BusinessConcepts.BusinessConceptVersion
  alias TdBg.BusinessConcepts.Search.Query
  alias TdBg.Permissions, as: TdBgPermissions
  alias TdBg.Taxonomies
  alias TdCore.Search
  alias TdCore.Search.ElasticDocumentProtocol
  alias TdCore.Search.Permissions

  @index :concepts

  def get_filter_values(%Claims{} = claims, params) do
    query_data = %{aggs: aggs} = ElasticDocumentProtocol.query_data(%BusinessConceptVersion{})
    query = build_query(claims, params, query_data)
    search = %{query: query, aggs: aggs, size: 0}

    {:ok, response} = Search.get_filters(search, @index)

    response
  end

  def search_business_concept_versions(params, claims, page \\ 0, size \\ 50)

  def search_business_concept_versions(%{"scroll_id" => _} = params, _claims, _page, _size) do
    params
    |> Map.take(["scroll", "scroll_id"])
    |> do_search()
  end

  def search_business_concept_versions(params, %Claims{} = claims, page, size) do
    query_data = ElasticDocumentProtocol.query_data(%BusinessConceptVersion{})
    query = build_query(claims, params, query_data)

    sort = Map.get(params, "sort", ["_score", "name.raw"])

    do_search(%{from: page * size, size: size, query: query, sort: sort}, params)
  end

  defp build_query(%Claims{} = claims, params, query_data) do
    opts = builder_opts(params)
    permissions = TdBgPermissions.get_default_permissions()

    permissions
    |> Permissions.get_search_permissions(claims)
    |> Query.build_filters(opts)
    |> Query.build_query(params, query_data)
  end

  defp builder_opts(%{"only_linkable" => true}), do: [linkable: true]
  defp builder_opts(_), do: []

  def count(query) do
    %{query: query, size: 0}
    |> do_search()
    |> Map.get(:total)
  end

  defp do_search(search, params \\ %{})

  defp do_search(%{"scroll_id" => _scroll_id} = search, _params) do
    case Search.scroll(search) do
      {:ok, %{results: results, total: total, scroll_id: scroll_id}} ->
        results
        |> map_results(total)
        |> Map.put(:scroll_id, scroll_id)

      {:ok, %{results: results, total: total}} ->
        map_results(results, total)
    end
  end

  defp do_search(search, %{"scroll" => scroll}) do
    case Search.search(search, :concepts, params: %{"scroll" => scroll}) do
      {:ok, %{results: results, total: total, scroll_id: scroll_id}} ->
        results
        |> map_results(total)
        |> Map.put(:scroll_id, scroll_id)
    end
  end

  defp do_search(search, _params) do
    case Search.search(search, :concepts) do
      {:ok, %{results: results, total: total}} ->
        map_results(results, total)
    end
  end

  defp map_results(results, total), do: %{results: Enum.map(results, &map_result/1), total: total}

  defp map_result(%{"_source" => source}) do
    map_result(source)
  end

  defp map_result(%{"domain" => %{"id" => domain_id}} = source) do
    parents = Taxonomies.get_parents(domain_id)
    Map.put(source, "domain_parents", parents)
  end

  defp map_result(%{} = source), do: source
end
