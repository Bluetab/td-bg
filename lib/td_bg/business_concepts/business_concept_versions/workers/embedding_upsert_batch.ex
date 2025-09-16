defmodule TdBg.BusinessConcepts.BusinessConceptVersions.Workers.EmbeddingsUpsertBatch do
  @moduledoc """
  Upsert embeddings in database given a list of concept ids.
  """
  use Oban.Worker, queue: :embedding_upserts, max_attempts: 5

  require Logger

  alias TdBg.BusinessConcepts.RecordEmbeddings

  def perform(%Oban.Job{args: %{"ids" => ids}}) do
    {count, nil} = RecordEmbeddings.upsert_from_concepts(ids)
    Logger.info("upserted #{count} record embeddings")
  end
end
