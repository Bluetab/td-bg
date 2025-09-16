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

  @batch_size 128

  def upsert_from_concepts_async(business_concept_ids, opts \\ []) do
    case Indices.exists_enabled?() do
      {:ok, true} ->
        Repo.transaction(fn ->
          business_concept_ids
          |> List.wrap()
          |> Stream.chunk_every(@batch_size)
          |> Stream.map(&EmbeddingsUpsertBatch.new(%{"ids" => &1}, opts))
          |> Oban.insert_all()
          |> Enum.to_list()
        end)

      _ ->
        :noop
    end
  end

  def upsert_from_concepts(business_concept_ids) do
    case Indices.exists_enabled?() do
      {:ok, true} ->
        now = DateTime.utc_now()

        records =
          business_concept_ids
          |> BusinessConcepts.get_all_versions_by_business_concept_ids(
            preload: [business_concept: :domain]
          )
          |> Enum.chunk_every(@batch_size)
          |> Enum.flat_map(fn versions ->
            {:ok, embedding_by_collection} = BusinessConcepts.embeddings(versions)
            record_embeddings(embedding_by_collection, versions)
          end)

        RecordEmbedding
        |> Repo.insert_all(records,
          placeholders: %{now: now},
          conflict_target: [:business_concept_version_id, :collection],
          on_conflict: {:replace, [:embedding, :dims, :updated_at]}
        )
        |> tap(fn _ -> Indexer.put_embeddings(business_concept_ids) end)

      _ ->
        :noop
    end
  end

  def upsert_outdated_async(opts \\ []) do
    case Indices.list(enabled: true) do
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
    case Indices.list(enabled: true) do
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
