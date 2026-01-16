defmodule TdBg.BusinessConcepts.RecordEmbeddings do
  @moduledoc """
  Context to manage record embeddings
  """
  import Ecto.Query

  alias TdBg.BusinessConcepts
  alias TdBg.BusinessConcepts.BusinessConceptVersions.RecordEmbedding
  alias TdBg.BusinessConcepts.BusinessConceptVersions.Workers.EmbeddingsUpsertBatch
  alias TdBg.Repo
  alias TdBg.Search.Indexer
  alias TdCluster.Cluster.TdAi.Indices

  require Logger

  @batch_size Application.compile_env(:td_bg, :record_embeddings_batch_size, 50)
  @default_delay_ms Application.compile_env(:td_bg, :record_embeddings_default_delay_ms, 500)
  @index_type "suggestions"

  def upsert_from_concepts_async(business_concept_ids, opts \\ []) do
    case Indices.exists_enabled?(index_type: @index_type) do
      {:ok, true} ->
        delay_ms = Keyword.get(opts, :delay_ms, @default_delay_ms)

        Repo.transaction(fn ->
          business_concept_ids
          |> List.wrap()
          |> Stream.chunk_every(@batch_size)
          |> Stream.with_index()
          |> Stream.map(&build_embeddings_job(&1, delay_ms, opts))
          |> Oban.insert_all()
          |> Enum.to_list()
        end)

      _ ->
        :noop
    end
  end

  defp build_embeddings_job({ids, index}, delay_ms, opts) do
    job_opts =
      if delay_ms > 0 do
        schedule_in_seconds = div(index * delay_ms, 1000)
        Keyword.put(opts, :schedule_in, schedule_in_seconds)
      else
        opts
      end

    EmbeddingsUpsertBatch.new(%{"ids" => ids}, job_opts)
  end

  def upsert_from_concepts(business_concept_ids) do
    ## TODO TD-7555: Inconsistent behavior: Verify if the provider is correctly configured.
    case Indices.exists_enabled?(index_type: @index_type) do
      {:ok, true} ->
        now = DateTime.utc_now()

        records =
          business_concept_ids
          |> BusinessConcepts.get_all_versions_by_business_concept_ids(
            preload: [business_concept: :domain]
          )
          |> Enum.chunk_every(@batch_size)
          |> Enum.with_index()
          |> Enum.flat_map(&process_versions_batch/1)

        RecordEmbedding
        |> Repo.insert_all(records,
          placeholders: %{now: now},
          conflict_target: [:business_concept_version_id, :collection],
          on_conflict: {:replace, [:embedding, :dims, :updated_at]}
        )
        |> tap(fn _ -> Indexer.put_embeddings(business_concept_ids) end)

      error ->
        Logger.error("Error generating embeddings for business concepts: #{inspect(error)}")
        error
    end
  end

  defp process_versions_batch({versions, batch_index}) do
    case BusinessConcepts.embeddings(versions) do
      {:ok, embedding_by_collection} ->
        record_embeddings(embedding_by_collection, versions)

      {:error, error} ->
        Logger.error("Error generating embeddings for batch #{batch_index}: #{inspect(error)}")

        []
    end
  end

  def upsert_outdated_async(opts \\ []) do
    case Indices.list(enabled: true, index_type: @index_type) do
      ## TODO TD-7555: Inconsistent behavior: Verify if the provider is correctly configured.
      {:ok, [_ | _] = indices} ->
        indices
        |> Enum.map(& &1.collection_name)
        |> BusinessConcepts.versions_with_outdated_embeddings(opts)
        |> upsert_from_concepts_async()

      _other ->
        :noop
    end
  end

  def delete_stale_record_embeddings do
    case Indices.list(enabled: true, index_type: @index_type) do
      {:ok, [_ | _] = indices} ->
        collections = Enum.map(indices, & &1.collection_name)

        RecordEmbedding
        |> where([re], re.collection not in ^collections)
        |> join(:inner, [re, bcv], bcv in assoc(re, :business_concept_version))
        |> select([re], re)
        |> Repo.delete_all()

      {:ok, []} ->
        Repo.delete_all(RecordEmbedding)

      _ ->
        :noop
    end
  end

  defp record_embeddings(embedding_by_collection, business_concept_versions) do
    Enum.flat_map(embedding_by_collection, fn {collection_name, embeddings} ->
      business_concept_versions
      |> Enum.zip(embeddings)
      |> Enum.map(fn {business_concept_version, embedding} ->
        %{
          business_concept_version_id: business_concept_version.id,
          embedding: embedding,
          dims: length(embedding),
          collection: collection_name,
          inserted_at: {:placeholder, :now},
          updated_at: {:placeholder, :now}
        }
      end)
    end)
  end
end
