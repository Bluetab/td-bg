defmodule TdBg.Search.Reindex do
  @moduledoc """
  A startup task to check for the existence of expected indexes in
  Elasticsearch, and to create them if they don't exist.
  """

  use Task

  alias TdBg.Search.Cluster
  alias TdBg.Search.IndexWorker
  alias TdCache.Redix

  require Logger

  def start_link(_arg) do
    Task.start_link(__MODULE__, :run, [])
  end

  def run do
    unless alias_exists?("concepts") do
      delete_existing_index("business_concept")

      if aquire_lock?() do
        IndexWorker.reindex(:all)
      else
        Logger.warn("Another process is reindexing")
      end
    end
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

  # Ensure only one instance of bg is reindexing by creating a lock in Redis
  defp aquire_lock? do
    case Redix.command!(["SET", "TdBg.Search.Reindex:LOCK", node(), "NX", "EX", 3600]) do
      "OK" -> true
      _ -> false
    end
  end
end
