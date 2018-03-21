defmodule TdBg.Search do
  alias TdBg.Taxonomies.DomainGroup
  alias TdBg.Taxonomies.DataDomain
  alias TdBg.BusinessConcepts.BusinessConceptVersion
  alias TdBg.ESClientApi

  @moduledoc """
    Search Engine calls
  """

  # CREATE AND UPDATE
  def put_search(%DomainGroup{} = domain_group) do
    ESClientApi.index_content("domain_group", domain_group.id, %{name: domain_group.name, description: domain_group.description, parent_id: domain_group.parent_id} |> Poison.encode!)
  end

  def put_search(%DataDomain{} = data_domain) do
    ESClientApi.index_content("data_domain", data_domain.id, %{name: data_domain.name, description: data_domain.description, domain_group_id: data_domain.domain_group_id}  |> Poison.encode!)
  end

  def put_search(%BusinessConceptVersion{} = concept) do
    ESClientApi.index_content("business_concept", concept.id,
      %{data_domain_id: concept.business_concept.data_domain_id, name: concept.name, status: concept.status, type: concept.business_concept.type, content: concept.content,
        description: concept.description, last_change_at: concept.business_concept.last_change_at}  |> Poison.encode!)
  end

  # DELETE
  def delete_search(%DomainGroup{} = domain_group) do
    ESClientApi.delete_content("domain_group", domain_group.id)
  end

  def delete_search(%DataDomain{} = data_domain) do
    ESClientApi.delete_content("data_domain", data_domain.id)
  end

  def delete_search(%BusinessConceptVersion{} = concept) do
    ESClientApi.delete_content("business_concept", concept.id)
  end

end
