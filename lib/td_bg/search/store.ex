defmodule TdBg.Search.Store do
  @moduledoc """
  Elasticsearch store implementation for Business Glossary
  """

  @behaviour Elasticsearch.Store

  import Ecto.Query

  alias TdBg.Repo

  @impl true
  def stream(schema) do
    schema
    |> Repo.stream()
    |> Repo.stream_preload(1000, business_concept: :domain)
    |> Stream.reject(&domain_deleted?/1)
  end

  @impl true
  def transaction(fun) do
    {:ok, result} = Repo.transaction(fun, timeout: :infinity)
    result
  end

  def stream(schema, ids) do
    from(bcv in schema,
      where: bcv.business_concept_id in ^ids,
      select: bcv
    )
    |> Repo.stream()
    |> Repo.stream_preload(1000, business_concept: :domain)
    |> Stream.reject(&domain_deleted?/1)
  end

  defp domain_deleted?(%{business_concept: %{domain: %{deleted_at: deleted_at}}})
       when not is_nil(deleted_at),
       do: true

  defp domain_deleted?(_), do: false
end
