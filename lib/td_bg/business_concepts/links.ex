defmodule TdBg.BusinessConcepts.Links do
  @moduledoc """
  The BusinessConcepts Links context.
  """

  alias TdBg.BusinessConcepts.BusinessConcept
  alias TdBg.BusinessConcepts.BusinessConceptVersion
  alias TdCache.LinkCache

  def get(id) do
    LinkCache.get(id)
  end

  def delete(id) do
    LinkCache.delete(id)
  end

  def get_links(%BusinessConceptVersion{business_concept_id: business_concept_id}) do
    get_links(business_concept_id)
  end

  def get_links(%BusinessConcept{id: id}), do: get_links(id)

  def get_links(business_concept_id) when is_integer(business_concept_id) do
    {:ok, links} = LinkCache.list("business_concept", business_concept_id)
    links
  end
end
