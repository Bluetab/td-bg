defmodule TdBg.BusinessConcepts.BusinessConceptVersions.Workers.EmbeddingsDeletion do
  @moduledoc """
  Deletes stale record embeddings.
  """

  use Oban.Worker, queue: :embedding_deletion, max_attempts: 5

  alias TdBg.BusinessConcepts.RecordEmbeddings

  require Logger

  def perform(%Oban.Job{}) do
    case RecordEmbeddings.delete_stale_record_embeddings() do
      {count, _response} when is_integer(count) ->
        Logger.info("Deleted #{count} record embeddings")

      {:error, error} ->
        Logger.error("Unexpected error #{inspect(error)} occurred")
    end
  end
end
