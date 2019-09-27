defmodule TdBg.Search.Store do
  @moduledoc """
  Elasticsearch store implementation for Business Glossary
  """

  @behaviour Elasticsearch.Store

  import Ecto.Query

  alias TdBg.BusinessConcepts.BusinessConceptVersion
  alias TdBg.BusinessConcepts.Indexable
  alias TdBg.Repo

  @impl true
  def stream(Indexable) do
    Repo.stream(
      from(bcv in BusinessConceptVersion,
        join: bc in assoc(bcv, :business_concept),
        join: d in assoc(bc, :domain),
        select: %Indexable{business_concept_version: bcv, type: bc.type, domain: d}
      )
    )
  end

  @impl true
  def transaction(fun) do
    {:ok, result} = Repo.transaction(fun, timeout: :infinity)
    result
  end
end
