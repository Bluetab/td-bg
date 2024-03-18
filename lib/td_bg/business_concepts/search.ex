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
    query = build_query(claims, params)

    aggs = ElasticDocumentProtocol.aggregations(%BusinessConceptVersion{})
    search = %{query: query, aggs: aggs, size: 0}

    {:ok, response} = Search.get_filters(search, @index)

    response
  end

  def search_business_concept_versions(params, claims, page \\ 0, size \\ 50)

  def search_business_concept_versions(params, %Claims{} = claims, page, size) do
    query = build_query(claims, params)

    sort = Map.get(params, "sort", ["_score", "name.raw"])

    do_search(%{from: page * size, size: size, query: query, sort: sort})
  end

  defp build_query(%Claims{} = claims, params) do
    opts = builder_opts(params)
    permissions = TdBgPermissions.get_default_permissions()

    permissions
    |> Permissions.get_search_permissions(claims)
    |> Query.build_filters(opts)
    |> Query.build_query(params)
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
    case Search.search(search, :concepts) do
      {:ok, %{results: results, total: total}} ->
        %{results: Enum.map(results, &map_result/1), total: total}
    end
  end

  defp map_result(%{"_source" => source}) do
    map_result(source)
  end

  defp map_result(%{"domain" => %{"id" => domain_id}} = source) do
    parents = Taxonomies.get_parents(domain_id)
    Map.put(source, "domain_parents", parents)
  end

  defp map_result(%{} = source), do: source
end
