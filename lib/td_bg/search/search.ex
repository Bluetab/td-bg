defmodule TdBg.Search do
  @moduledoc """
  Search Engine calls
  """

  alias Elasticsearch.Index.Bulk
  alias TdBg.BusinessConcepts.BusinessConceptVersion
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
      |> Enum.map(&Bulk.encode!(Cluster, &1, @index, "index"))
      |> Enum.join("")

    Elasticsearch.post(Cluster, "/#{@index}/_doc/_bulk", bulk)
  end

  def delete_search(%BusinessConceptVersion{} = concept) do
    Elasticsearch.delete_document(Cluster, concept, @index)
  end

  def search(query) do
    Logger.debug(fn -> "Query: #{inspect(query)}" end)
    response = Elasticsearch.post(Cluster, "/#{@index}/_search", query)

    case response do
      {:ok, %{"hits" => %{"hits" => results, "total" => total}}} ->
        %{results: results, total: total}

      {:error, %Elasticsearch.Exception{message: message} = error} ->
        Logger.warn("Error response from Elasticsearch: #{message}")
        error
    end
  end

  def get_filters(query) do
    response = Elasticsearch.post(Cluster, "/#{@index}/_search", query)

    case response do
      {:ok, %{"aggregations" => aggregations}} ->
        aggregations
        |> Map.to_list()
        |> Enum.into(%{}, &filter_values/1)

      {:error, %Elasticsearch.Exception{message: message} = error} ->
        Logger.warn("Error response from Elasticsearch: #{message}")
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
