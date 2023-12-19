defmodule TdBg.Search.Store do
  @moduledoc """
  Elasticsearch store implementation for Business Glossary
  """

  @behaviour Elasticsearch.Store

  import Ecto.Query

  alias TdBg.BusinessConcepts.BusinessConceptVersion
  alias TdBg.Repo
  alias TdCluster.Cluster.TdDd.Tasks

  @impl true
  def stream(BusinessConceptVersion = schema) do
    count = Repo.aggregate(BusinessConceptVersion, :count, :id)
    Tasks.log_start_stream(count)

    result =
      schema
      |> Repo.stream()
      |> Repo.stream_preload(1000, business_concept: [:domain, :shared_to])
      |> Stream.reject(&domain_deleted?/1)

    Tasks.log_progress(count)

    result
  end

  @impl true
  def transaction(fun) do
    {:ok, result} = Repo.transaction(fun, timeout: :infinity)
    result
  end

  def stream(BusinessConceptVersion = schema, ids) do
    count = Repo.aggregate(BusinessConceptVersion, :count, :id)
    Tasks.log_start_stream(count)

    from(bcv in schema,
      where: bcv.business_concept_id in ^ids,
      select: bcv
    )
    |> Repo.stream()
    |> Repo.stream_preload(1000, business_concept: [:domain, :shared_to])
    |> Stream.reject(&domain_deleted?/1)
  end

  defp domain_deleted?(%{business_concept: %{domain: %{deleted_at: deleted_at}}})
       when not is_nil(deleted_at),
       do: true

  defp domain_deleted?(_), do: false
end
