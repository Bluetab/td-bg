defmodule TdBg.Search.Store do
  @moduledoc """
  Elasticsearch store implementation for Business Glossary
  """

  @behaviour Elasticsearch.Store

  import Ecto.Query

  alias TdBg.BusinessConcepts.BusinessConceptVersion
  alias TdBg.BusinessConcepts.BusinessConceptVersions.RecordEmbedding
  alias TdBg.BusinessConcepts.BusinessConceptVersions.Workers.OutdatedEmbeddings
  alias TdBg.Repo
  alias TdCluster.Cluster.TdAi.Indices
  alias TdCluster.Cluster.TdDd.Tasks

  @index_type "suggestions"

  @impl true
  def stream(BusinessConceptVersion = schema) do
    count = Repo.aggregate(BusinessConceptVersion, :count, :id)
    Tasks.log_start_stream(count)

    result =
      schema
      |> Repo.stream()
      |> Repo.stream_preload(1000, [:record_embeddings, business_concept: [:domain, :shared_to]])
      |> Stream.reject(&domain_deleted?/1)

    Tasks.log_progress(count)

    result
  end

  @impl true
  def transaction(fun) do
    {:ok, result} = Repo.transaction(fun, timeout: :infinity)
    result
  end

  def stream(BusinessConceptVersion, {:embeddings, ids}) do
    case Indices.list(enabled: true, index_type: @index_type) do
      {:ok, [_ | _] = indices} ->
        collections = Enum.map(indices, & &1.collection_name)

        BusinessConceptVersion
        |> where([bcv], bcv.business_concept_id in ^ids)
        |> join(:inner, [bcv, bc], bc in assoc(bcv, :business_concept))
        |> join(:inner, [bcv, bc, d], d in assoc(bc, :domain))
        |> join(:inner, [bcv, bc, d, re], re in RecordEmbedding,
          on: re.business_concept_version_id == bcv.id and re.collection in ^collections
        )
        |> where([bcv, bc, d, re], is_nil(d.deleted_at))
        |> group_by([bcv, bc, d, re], bcv.id)
        |> select([bcv, bc, d, re], %BusinessConceptVersion{
          bcv
          | record_embeddings: fragment("array_agg(row_to_json(?))", re)
        })
        |> Repo.stream()
        |> Stream.map(fn %BusinessConceptVersion{record_embeddings: record_embeddings} = bcv ->
          record_embeddings = Enum.map(record_embeddings, &RecordEmbedding.coerce/1)
          embeddings = BusinessConceptVersion.vector_embeddings(record_embeddings)

          %BusinessConceptVersion{
            bcv
            | record_embeddings: record_embeddings,
              embeddings: embeddings
          }
        end)

      _other ->
        []
    end
  end

  def stream(BusinessConceptVersion = schema, ids) do
    count = Repo.aggregate(BusinessConceptVersion, :count, :id)
    Tasks.log_start_stream(count)

    from(bcv in schema,
      where: bcv.business_concept_id in ^ids,
      select: bcv
    )
    |> Repo.stream()
    |> Repo.stream_preload(1000, [:record_embeddings, business_concept: [:domain, :shared_to]])
    |> Stream.reject(&domain_deleted?/1)
  end

  def run(BusinessConceptVersion, {:embeddings, :all}) do
    %{}
    |> OutdatedEmbeddings.new()
    |> Oban.insert()
  end

  defp domain_deleted?(%{business_concept: %{domain: %{deleted_at: deleted_at}}})
       when not is_nil(deleted_at),
       do: true

  defp domain_deleted?(_), do: false
end
