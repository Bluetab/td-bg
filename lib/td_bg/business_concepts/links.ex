defmodule TdBg.BusinessConcepts.Links do
  @moduledoc """
  The BusinessConcepts Links context.
  """

  import Canada, only: [can?: 2]

  alias TdBg.BusinessConcepts.BusinessConcept
  alias TdBg.BusinessConcepts.BusinessConceptVersion
  alias TdCache.LinkCache

  def get(id) do
    LinkCache.get(id)
  end

  def delete(id) do
    LinkCache.delete(id)
  end

  def get_links(concept, opts \\ [])

  def get_links(%BusinessConceptVersion{business_concept_id: business_concept_id}, opts) do
    get_links(business_concept_id, opts)
  end

  def get_links(%BusinessConcept{id: id}, opts), do: get_links(id, opts)

  def get_links(business_concept_id, opts) do
    {target_type, opts} = Keyword.pop(opts, :target_type)
    get_links(business_concept_id, target_type, opts)
  end

  def get_links(business_concept_id, target_type, opts) when is_binary(target_type) do
    {:ok, links} = LinkCache.list("business_concept", business_concept_id, target_type, opts)
    links
  end

  def get_links(business_concept_id, nil, opts) do
    {:ok, links} = LinkCache.list("business_concept", business_concept_id, opts)
    links
  end

  def has_permissions?(claims, %{resource_type: :data_structure, domain_ids: domain_ids})
      when is_list(domain_ids) do
    can?(claims, view_data_structure(domain_ids))
  end

  def has_permissions?(claims, %{resource_type: :data_structure}) do
    can?(claims, view_data_structure(:no_domain))
  end
end
