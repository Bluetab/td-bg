defmodule TdBg.Search.Indexer do
  @moduledoc """
  Manages elasticsearch indices
  """
  alias Elasticsearch.Index
  alias Elasticsearch.Index.Bulk
  alias Jason, as: JSON
  alias TdBg.Search.Cluster
  alias TdBg.Search.Mappings
  alias TdBg.Search.Store

  @index "concepts"
  @index_config Application.get_env(:td_bg, TdBg.Search.Cluster, :indexes)

  require Logger

  def reindex(:business_concept) do
    template =
      Mappings.get_mappings()
      |> Map.put(:index_patterns, "#{@index}-*")
      |> JSON.encode!()

    {:ok, _} = Elasticsearch.put(Cluster, "/_template/#{@index}", template)

    Index.hot_swap(Cluster, @index)
  end

  def reindex(ids, :business_concept) do
    %{bulk_page_size: bulk_page_size} =
      @index_config
      |> Keyword.get(:indexes)
      |> Map.get(:concepts)

    ids
    |> Stream.chunk_every(bulk_page_size)
    |> Stream.map(&Store.list(&1))
    |> Stream.map(fn chunk ->
      time(bulk_page_size, fn ->
        bulk =
          chunk
          |> Enum.map(&Bulk.encode!(Cluster, &1, @index, "index"))
          |> Enum.join("")

        Elasticsearch.post(Cluster, "/#{@index}/_doc/_bulk", bulk)
      end)
    end)
    |> Stream.run()
  end

  def delete(business_concept_versions) when is_list(business_concept_versions) do
    Enum.each(business_concept_versions, &delete/1)
  end

  def delete(business_concept_version) do
    Elasticsearch.delete_document(Cluster, business_concept_version, @index)
  end

  defp time(bulk_page_size, fun) do
    {millis, res} = Timer.time(fun)

    case millis do
      0 ->
        Logger.info("Indexing rate :infinity items/s")

      millis ->
        rate = div(1_000 * bulk_page_size, millis)
        Logger.info("Indexing rate #{rate} items/s")
    end

    res
  end
end
