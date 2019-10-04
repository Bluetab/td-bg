defmodule TdBg.Search.Indexer do
  @moduledoc """
  Manages elasticsearch indices
  """
  alias Elasticsearch.Index
  alias Elasticsearch.Index.Bulk
  alias Jason, as: JSON
  alias TdBg.BusinessConcepts.BusinessConceptVersion
  alias TdBg.Search.Cluster
  alias TdBg.Search.Mappings
  alias TdBg.Search.Store
  alias TdCache.Redix

  require Logger

  @index :concepts

  def reindex(:all) do
    {:ok, _} =
      Mappings.get_mappings()
      |> Map.put(:index_patterns, "#{@index}-*")
      |> JSON.encode!()
      |> put_template(@index)

    Index.hot_swap(Cluster, @index)
  end

  def reindex(ids) do
    Store.transaction(fn ->
      BusinessConceptVersion
      |> Store.stream(ids)
      |> Stream.map(&Bulk.encode!(Cluster, &1, @index, "index"))
      |> Stream.chunk_every(bulk_page_size(@index))
      |> Stream.map(&Enum.join(&1, ""))
      |> Stream.map(&Elasticsearch.post(Cluster, "/#{@index}/_doc/_bulk", &1))
      |> Stream.run()
    end)
  end

  def delete(business_concept_versions) when is_list(business_concept_versions) do
    Enum.each(business_concept_versions, &delete/1)
  end

  def delete(business_concept_version) do
    Elasticsearch.delete_document(Cluster, business_concept_version, "#{@index}")
  end

  def migrate do
    unless alias_exists?(@index) do
      if can_migrate?() do
        delete_existing_index("business_concept")

        Timer.time(
          fn -> reindex(:all) end,
          fn millis, _ -> Logger.info("Migrated index #{@index} in #{millis}ms") end
        )
      else
        Logger.warn("Another process is migrating")
      end
    end
  end

  defp bulk_page_size(index) do
    :td_bg
    |> Application.get_env(Cluster)
    |> Keyword.get(:indexes)
    |> Map.get(index)
    |> Map.get(:bulk_page_size)
  end

  defp put_template(template, name) do
    Elasticsearch.put(Cluster, "/_template/#{name}", template)
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
