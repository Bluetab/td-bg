defmodule TdBg.Search.Indexer do
  @moduledoc """
  Manages elasticsearch indices
  """
  alias Jason, as: JSON
  alias TdBg.BusinessConcepts
  alias TdBg.Search
  alias TdBg.Search.Cluster
  alias TdBg.Search.Mappings

  def reindex(:business_concept) do
    template =
      Mappings.get_mappings()
      |> Map.put(:index_patterns, "concepts-*")
      |> JSON.encode!()

    {:ok, _} = Elasticsearch.put(Cluster, "/_template/concepts", template)

    Search.put_bulk_search(:business_concept)
  end

  def reindex(business_concept_ids, :business_concept) do
    business_concept_ids
    |> Enum.flat_map(&BusinessConcepts.list_business_concept_versions(&1, nil))
    |> Search.put_bulk_search(:business_concept)
  end
end
