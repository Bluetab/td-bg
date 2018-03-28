defmodule TdBg.Search do

  require Logger
  alias TdBg.Taxonomies.DomainGroup
  alias TdBg.Taxonomies.DataDomain
  alias TdBg.BusinessConcepts.BusinessConceptVersion
  alias TdBg.ESClientApi
  alias TdBg.BusinessConcepts
  alias TdBg.Taxonomies

  @moduledoc """
    Search Engine calls
  """

  def put_bulk_search(:domain_group) do
    domain_groups = Taxonomies.list_domain_groups()
    Enum.each(domain_groups, fn(dg)->
      put_search(dg)
    end)
  end

  def put_bulk_search(:data_domain) do
    data_domains = Taxonomies.list_data_domains()
    Enum.each(data_domains, fn(dd)->
      put_search(dd)
    end)
  end

  def put_bulk_search(:business_concept) do
    business_concepts = BusinessConcepts.list_all_business_concept_versions()
    Enum.each(business_concepts, fn(bc)->
      put_search(bc)
    end)
  end

  # CREATE AND UPDATE
  def put_search(%DomainGroup{} = domain_group) do
    response = ESClientApi.index_content("domain_group", domain_group.id, domain_group.__struct__.search_fields(domain_group) |> Poison.encode!)
    case response do
      {:ok, %HTTPoison.Response{status_code: status}} ->
        Logger.info "Domain group #{domain_group.name} created/updated status #{status}"
      {:error, _error} ->
        Logger.error "Error creating/updating domain group #{domain_group.name}"
    end
  end

  def put_search(%DataDomain{} = data_domain) do
    response = ESClientApi.index_content("data_domain", data_domain.id, data_domain.__struct__.search_fields(data_domain)  |> Poison.encode!)
    case response do
      {:ok, %HTTPoison.Response{status_code: status}} ->
        Logger.info "Data domain #{data_domain.name} created/updated status #{status}"
      {:error, _error} ->
        Logger.error "Error creating/updating data domain #{data_domain.name}"
    end
  end

  def put_search(%BusinessConceptVersion{} = concept) do

    response = ESClientApi.index_content("business_concept", concept.id, concept.__struct__.search_fields(concept) |> Poison.encode!)
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
      {:error, %HTTPoison.Error{reason: :econnrefused}} ->
        Logger.error "Error connecting to ES"
    end
  end

  def delete_search(%DataDomain{} = data_domain) do
    response = ESClientApi.delete_content("data_domain", data_domain.id)
    case response do
      {_, %HTTPoison.Response{status_code: 200}} ->
        Logger.info "Data domain #{data_domain.name} deleted status 200"
      {_, %HTTPoison.Response{status_code: status_code}} ->
        Logger.error "Error deleting data domain #{data_domain.name} status #{status_code}"
      {:error, %HTTPoison.Error{reason: :econnrefused}} ->
        Logger.error "Error connecting to ES"
    end
  end

  def delete_search(%BusinessConceptVersion{} = concept) do
    response = ESClientApi.delete_content("business_concept", concept.id)
    case response do
      {_, %HTTPoison.Response{status_code: 200}} ->
        Logger.info "Business concept #{concept.name} deleted status 200"
      {_, %HTTPoison.Response{status_code: status_code}} ->
        Logger.error "Error deleting business concept #{concept.name} status #{status_code}"
      {:error, %HTTPoison.Error{reason: :econnrefused}} ->
        Logger.error "Error connecting to ES"
    end
  end

  def search(index_name, query) do
    response = ESClientApi.search_es(index_name, query)
    case response do
      {:ok, %HTTPoison.Response{body: %{"hits" => %{"hits" => results}}}} ->
        results
      {:ok, %HTTPoison.Response{body: error}} ->
        error
    end
  end

end
