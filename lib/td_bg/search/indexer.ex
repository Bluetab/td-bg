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
  alias TdCache.Redix

  @index "concepts"
  @index_config Application.get_env(:td_bg, TdBg.Search.Cluster, :indexes)

  require Logger

  def reindex(:all) do
    template =
      Mappings.get_mappings()
      |> Map.put(:index_patterns, "#{@index}-*")
      |> JSON.encode!()

    {:ok, _} = Elasticsearch.put(Cluster, "/_template/#{@index}", template)

    Index.hot_swap(Cluster, @index)
  end

  def reindex(ids) do
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

  def migrate do
    unless alias_exists?(@index) do
      if can_migrate?() do
        delete_existing_index(@index)

        Timer.time(
          fn -> reindex(:all) end,
          fn millis, _ -> Logger.info("Migrated index #{@index} in #{millis}ms") end
        )
      else
        Logger.warn("Another process is migrating")
      end
    end
  end

  defp time(bulk_page_size, fun) do
    Timer.time(
      fun,
      fn millis, _ ->
        case millis do
          0 ->
            Logger.info("Indexing rate :infinity items/s")

          millis ->
            rate = div(1_000 * bulk_page_size, millis)
            Logger.info("Indexing rate #{rate} items/s")
        end
      end
    )
  end

  defp alias_exists?(name) do
    case Elasticsearch.head(Cluster, "/_alias/#{name}") do
      {:ok, _} -> true
      {:error, _} -> false
    end
  end

  defp delete_existing_index(name) do
    case Elasticsearch.delete(Cluster, "/#{name}") do
      {:ok, _} ->
        Logger.info("Deleted index #{name}")

      {:error, %{status: 404}} ->
        :ok

      error ->
        error
    end
  end

  # Ensure only one instance of dq is reindexing by creating a lock in Redis
  defp can_migrate? do
    Redix.command!(["SET", "TdBg.Search.Indexer:LOCK", node(), "NX", "EX", 3600]) == "OK"
  end
end
