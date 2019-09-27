defmodule TdBg.Search.Indexer do
  @moduledoc """
  Manages elasticsearch indices
  """
  alias Jason, as: JSON
  alias TdBg.BusinessConcepts
  alias TdBg.ESClientApi
  alias TdBg.Search.Cluster
  alias TdBg.Search.Mappings

  @search_service Application.get_env(:td_bg, :elasticsearch)[:search_service]

  def reindex(:business_concept) do
    template = Mappings.get_mappings()
    |> Map.put(:index_patterns, "concepts-*")
    |> JSON.encode!()
    {:ok, _} = Elasticsearch.put(Cluster, "/_template/concepts", template)

    @search_service.put_bulk_search(:business_concept) # TODO tidy up...
  end

  def reindex(business_concept_ids, :business_concept) do
    business_concept_ids
    |> Enum.flat_map(&BusinessConcepts.list_business_concept_versions(&1, nil))
    |> @search_service.put_bulk_search(:business_concept)
  end
end
