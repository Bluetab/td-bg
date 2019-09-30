defmodule TdBg.Search do
  @moduledoc """
  Search Engine calls
  """

  alias Elasticsearch.Index.Bulk
  alias TdBg.BusinessConcepts.BusinessConceptVersion
  alias TdBg.ESClientApi
  alias TdBg.Search.Cluster

  require Logger

  @index "concepts"

  def put_bulk_search(:business_concept) do
    Elasticsearch.Index.hot_swap(Cluster, @index)
  end

  def put_bulk_search(business_concepts, :business_concept) do
    # TODO: stream, chunk
    bulk =
      business_concepts
      |> Enum.map(&Bulk.encode!(Cluster, &1, @index, action: "index"))
      |> Enum.join("")

    Elasticsearch.post(Cluster, @index <> "/_doc/_bulk", bulk)
  end

  def delete_search(%BusinessConceptVersion{} = concept) do
    Elasticsearch.delete_document(Cluster, concept, @index)
  end

  def search(index_name, query) do
    Logger.debug(fn -> "Query: #{inspect(query)}" end)
    response = ESClientApi.search_es(index_name, query)

    case response do
      {:ok, %HTTPoison.Response{body: %{"hits" => %{"hits" => results, "total" => total}}}} ->
        %{results: results, total: total}

      {:ok, %HTTPoison.Response{body: error}} ->
        error
    end
  end

  def get_filters(query) do
    response = ESClientApi.search_es("business_concept", query)

    case response do
      {:ok, %HTTPoison.Response{body: %{"aggregations" => aggregations}}} ->
        aggregations
        |> Map.to_list()
        |> Enum.into(%{}, &filter_values/1)

      {:ok, %HTTPoison.Response{body: error}} ->
        error
    end
  end

  defp filter_values({name, %{"buckets" => buckets}}) do
    {name, buckets |> Enum.map(& &1["key"])}
  end

  defp filter_values({name, %{"distinct_search" => distinct_search}}) do
    filter_values({name, distinct_search})
  end
end
