defmodule TdBg.Search.Indexer do
  @moduledoc """
  Indexer for Concepts.
  """

  alias TdBg.BusinessConcepts.RecordEmbeddings
  alias TdCore.Search.IndexWorker

  @index :concepts
  @schedule_in 60 * 30

  def reindex(ids) do
    IndexWorker.reindex(@index, ids)
    upsert_record_embeddings(ids)
    :ok
  end

  def delete(ids) do
    IndexWorker.delete(@index, ids)
    :ok
  end

  def put_embeddings(ids) do
    IndexWorker.put_embeddings(@index, ids)
    :ok
  end

  defp upsert_record_embeddings(:all), do: :noop

  defp upsert_record_embeddings(ids) do
    RecordEmbeddings.upsert_from_concepts_async(ids, schedule_in: @schedule_in)
  end
end
