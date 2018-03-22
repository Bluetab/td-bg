defmodule TdBg.Search do

  require Logger
  alias TdBg.Taxonomies.DomainGroup
  alias TdBg.Taxonomies.DataDomain
  alias TdBg.BusinessConcepts.BusinessConceptVersion
  alias TdBg.ESClientApi

  @moduledoc """
    Search Engine calls
  """

  # CREATE AND UPDATE
  def put_search(%DomainGroup{} = domain_group) do
    response = ESClientApi.index_content("domain_group", domain_group.id, %{name: domain_group.name, description: domain_group.description, parent_id: domain_group.parent_id} |> Poison.encode!)
    case response do
      {:ok, %HTTPoison.Response{status_code: status}} ->
        Logger.info "Domain group #{domain_group.name} created/updated status #{status}"
      {:error, _error} ->
        Logger.error "Error creating/updating domain group #{domain_group.name}"
    end
  end

  def put_search(%DataDomain{} = data_domain) do
    response = ESClientApi.index_content("data_domain", data_domain.id, %{name: data_domain.name, description: data_domain.description, domain_group_id: data_domain.domain_group_id}  |> Poison.encode!)
    case response do
      {:ok, %HTTPoison.Response{status_code: status}} ->
        Logger.info "Data domain #{data_domain.name} created/updated status #{status}"
      {:error, _error} ->
        Logger.error "Error creating/updating data domain #{data_domain.name}"
    end
  end

  def put_search(%BusinessConceptVersion{} = concept) do
    response = ESClientApi.index_content("business_concept", concept.id,
      %{data_domain_id: concept.business_concept.data_domain_id, name: concept.name, status: concept.status, type: concept.business_concept.type, content: concept.content,
        description: concept.description, last_change_at: concept.business_concept.last_change_at}  |> Poison.encode!)
    case response do
      {:ok, %HTTPoison.Response{status_code: status}} ->
        Logger.info "Business concept #{concept.name} created/updated status #{status}"
      {:error, _error} ->
        Logger.error "Error creating/updating business concept #{concept.name}"
    end
  end

  # DELETE
  def delete_search(%DomainGroup{} = domain_group) do
    response = ESClientApi.delete_content("domain_group", domain_group.id)
    case response do
      {_, %HTTPoison.Response{status_code: 200}} ->
        Logger.info "Domain group #{domain_group.name} deleted status 200"
      {_, %HTTPoison.Response{status_code: status_code}} ->
        Logger.error "Error deleting domain group #{domain_group.name} status #{status_code}"
    end
  end

  def delete_search(%DataDomain{} = data_domain) do
    response = ESClientApi.delete_content("data_domain", data_domain.id)
    case response do
      {_, %HTTPoison.Response{status_code: 200}} ->
        Logger.info "Data domain #{data_domain.name} deleted status 200"
      {_, %HTTPoison.Response{status_code: status_code}} ->
        Logger.error "Error deleting data domain #{data_domain.name} status #{status_code}"
    end
  end

  def delete_search(%BusinessConceptVersion{} = concept) do
    response = ESClientApi.delete_content("business_concept", concept.id)
    case response do
      {_, %HTTPoison.Response{status_code: 200}} ->
        Logger.info "Business concept #{concept.name} deleted status 200"
      {_, %HTTPoison.Response{status_code: status_code}} ->
        Logger.error "Error deleting business concept #{concept.name} status #{status_code}"
    end
  end

  def search(index_name, query) do
    response = ESClientApi.search_api(index_name, query)
    case response do
      {:ok, %HTTPoison.Response{body: %{"hits" => %{"hits" => results}}}} ->
        # IO.inspect(results)
    end
  end

end
