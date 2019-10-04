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
  end
end
