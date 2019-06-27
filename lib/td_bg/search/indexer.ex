defmodule TdBg.Search.Indexer do
  @moduledoc """
  Manages elasticsearch indices
  """
  alias TdBg.BusinessConcepts
  alias TdBg.ESClientApi
  alias TdBg.Search.Mappings

  @search_service Application.get_env(:td_bg, :elasticsearch)[:search_service]

  def reindex(:business_concept) do
    ESClientApi.delete!("business_concept")
    mapping = Mappings.get_mappings() |> Poison.encode!()
    %{status_code: 200} = ESClientApi.put!("business_concept", mapping)
    @search_service.put_bulk_search(:business_concept)
  end

  def reindex(business_concept_ids, :business_concept) do
    business_concept_ids
    |> Enum.flat_map(&BusinessConcepts.list_business_concept_versions(&1, nil))
    |> @search_service.put_bulk_search(:business_concept)
  end
end
