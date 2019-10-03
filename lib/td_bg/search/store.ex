defmodule TdBg.Search.Store do
  @moduledoc """
  Elasticsearch store implementation for Business Glossary
  """

  @behaviour Elasticsearch.Store

  import Ecto.Query

  alias TdBg.BusinessConcepts.BusinessConceptVersion
  alias TdBg.Repo

  @impl true
  def stream(BusinessConceptVersion) do
    query()
    |> Repo.stream()
    |> Stream.map(&preload/1)
  end

  @impl true
  def transaction(fun) do
    {:ok, result} = Repo.transaction(fun, timeout: :infinity)
    result
  end

  def list(ids) do
    ids
    |> query()
    |> Repo.all()
    |> Enum.map(&preload/1)
  end

  defp query do
    from(bcv in BusinessConceptVersion,
      join: c in assoc(bcv, :business_concept),
      join: d in assoc(c, :domain),
      select: {bcv, c, d}
    )
  end

  defp query(ids) do
    from(bcv in BusinessConceptVersion,
      join: c in assoc(bcv, :business_concept),
      join: d in assoc(c, :domain),
      where: c.id in ^ids,
      select: {bcv, c, d}
    )
  end

  defp preload({business_concept_version, business_concept, domain}) do
    business_concept = Map.put(business_concept, :domain, domain)
    Map.put(business_concept_version, :business_concept, business_concept)
  end
end
