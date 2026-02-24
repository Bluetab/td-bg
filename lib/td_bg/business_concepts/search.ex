defmodule TdBg.BusinessConcept.Search do
  @moduledoc """
  Helper module to construct business concept search queries.
  """

  alias Elasticsearch.Cluster.Config
  alias TdBg.Auth.Claims
  alias TdBg.BusinessConcepts.BusinessConceptVersion
  alias TdBg.BusinessConcepts.Search.Query
  alias TdBg.Permissions, as: TdBgPermissions
  alias TdBg.Taxonomies
  alias TdCore.Search
  alias TdCore.Search.Cluster
  alias TdCore.Search.ElasticDocumentProtocol
  alias TdCore.Search.Permissions

  @index :concepts

  def get_filter_values(%Claims{} = claims, params) do
    query_data = %{aggs: aggs} = ElasticDocumentProtocol.query_data(%BusinessConceptVersion{})
    query = build_query(claims, params, query_data)
    search = %{query: query, aggs: aggs, size: 0, _source: %{excludes: ["embeddings"]}}

    {:ok, response} = Search.get_filters(search, @index)

    response
  end

  def search_all(%Claims{} = claims, params) do
    params
    |> Map.drop(["page", "size"])
    |> search_business_concept_versions(claims, 0, 10_000)
  end

  def stream_all(%Claims{} = claims, params, size \\ 1_000) do
    sort = Map.get(params, "sort", ["_id"])
    keep_alive = Map.get(params, "keep_alive", "1m")

    query_data = ElasticDocumentProtocol.query_data(%BusinessConceptVersion{})
    query = build_query(claims, params, query_data)

    Stream.resource(
      fn ->
        {:ok, %{id: id}} = Search.create_pit(:concepts, %{"keep_alive" => keep_alive})
        %{query: query, sort: sort, pit: %{id: id, keep_alive: keep_alive}, size: size}
      end,
      &stream_paginate/1,
      fn %{pit: %{id: id}} -> Search.delete_pit(id) end
    )
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

    do_search(
      %{
        from: page * size,
        size: size,
        query: query,
        sort: sort,
        _source: %{excludes: ["embeddings"]}
      },
      params
    )
  end

  def vector(%Claims{} = claims, params, opts \\ []) do
    query_data = ElasticDocumentProtocol.query_data(%BusinessConceptVersion{})
    bool_query = build_query(claims, params, query_data)

    knn =
      params
      |> Map.take(["field", "query_vector", "k", "num_candidates", "similarity"])
      |> Map.put("filter", bool_query)

    %{knn: knn, _source: %{excludes: ["embeddings"]}, sort: ["_score"]}
    |> Search.search(@index)
    |> then(fn {:ok, %{results: results}} ->
      Enum.map(results, fn result ->
        result
        |> map_result()
        |> add_similarity(result, opts[:similarity])
      end)
    end)
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

  def store do
    cluster_config = Config.get(Cluster)
    store = get_in(cluster_config, [:indexes, :concepts, :store])

    schema =
      cluster_config
      |> get_in([:indexes, :concepts, :sources])
      |> List.first()

    %{store: store, schema: schema}
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

  defp do_search_after(search) do
    case Search.search_after(search) do
      {:ok, %{results: results, pit_id: _pit_id}} ->
        search_after_results(results)
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

  defp stream_paginate(%{search_after: nil} = body), do: {:halt, body}

  defp stream_paginate(body) do
    case do_search_after(body) do
      %{results: []} ->
        {:halt, body}

      %{results: [_ | _] = results, search_after: search_after} ->
        {[results], Map.put(body, :search_after, search_after)}
    end
  end

  defp search_after_results([]), do: %{results: []}

  defp search_after_results([_ | _] = results) do
    search_after = results |> List.last() |> Map.get("sort")
    %{search_after: search_after, results: Enum.map(results, &map_result/1)}
  end

  defp add_similarity(concept, record, :cosine) do
    # We assume cosine similarity by default, but this may vary depending on the index configuration.
    #  Adjust accordingly based on the actual setup
    # https://www.elastic.co/docs/solutions/search/vector/knn#knn-similarity-search
    similarity = 2 * record["_score"] - 1
    Map.put(concept, "similarity", similarity)
  end

  defp add_similarity(concept, _record, _other), do: concept
end
