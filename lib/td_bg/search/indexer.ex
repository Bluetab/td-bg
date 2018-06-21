defmodule TdBg.Search.Indexer do
  @moduledoc """
    Manages elasticsearch indices
  """
  alias TdBg.ESClientApi
  alias TdBg.Search
  alias TdBg.Search.Mappings

  def reindex(:business_concept) do
    ESClientApi.delete!("business_concept")
    mapping = Mappings.get_mappings() |> Poison.encode!()
    ESClientApi.put!("business_concept", mapping)
    Search.put_bulk_search(:business_concept)
  end
end
