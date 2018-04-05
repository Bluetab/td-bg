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
    {:ok, %HTTPoison.Response{body: response}} = ESClientApi.bulk_index_content(domain_groups)
    cond do
      response["errors"] == true ->
        {:error, response["errors"]}
      response["error"] == true ->
        {:error, response["error"]}
      true ->
      {:ok, response}
    end
  end

  def put_bulk_search(:data_domain) do
    data_domains = Taxonomies.list_data_domains()
    ESClientApi.bulk_index_content(data_domains)
  end

  def put_bulk_search(:business_concept) do
    business_concepts = BusinessConcepts.list_all_business_concept_versions()
    ESClientApi.bulk_index_content(business_concepts)
  end

  # CREATE AND UPDATE
  def put_search(%DomainGroup{} = domain_group) do
    search_fields = domain_group.__struct__.search_fields(domain_group)
    response = ESClientApi.index_content(domain_group.__struct__.index_name(), domain_group.id, search_fields |> Poison.encode!)
    case response do
      {:ok, %HTTPoison.Response{status_code: status}} ->
        Logger.info "Domain group #{domain_group.name} created/updated status #{status}"
      {:error, _error} ->
        Logger.error "ES: Error creating/updating domain group #{domain_group.name}"
    end
  end

  def put_search(%DataDomain{} = data_domain) do
    search_fields = data_domain.__struct__.search_fields(data_domain)
    response = ESClientApi.index_content(data_domain.__struct__.index_name(), data_domain.id, search_fields  |> Poison.encode!)
    case response do
      {:ok, %HTTPoison.Response{status_code: status}} ->
        Logger.info "Data domain #{data_domain.name} created/updated status #{status}"
      {:error, _error} ->
        Logger.error "ES: Error creating/updating data domain #{data_domain.name}"
    end
  end

  def put_search(%BusinessConceptVersion{} = concept) do
    search_fields = concept.__struct__.search_fields(concept)
    response = ESClientApi.index_content(concept.__struct__.index_name(), concept.id, search_fields |> Poison.encode!)
    case response do
      {:ok, %HTTPoison.Response{status_code: status}} ->
        Logger.info "Business concept #{concept.name} created/updated status #{status}"
      {:error, _error} ->
        Logger.error "ES: Error creating/updating business concept #{concept.name}"
    end
  end

  # DELETE
  def delete_search(%DomainGroup{} = domain_group) do
    response = ESClientApi.delete_content("domain_group", domain_group.id)
    case response do
      {_, %HTTPoison.Response{status_code: 200}} ->
        Logger.info "Domain group #{domain_group.name} deleted status 200"
      {_, %HTTPoison.Response{status_code: status_code}} ->
        Logger.error "ES: Error deleting domain group #{domain_group.name} status #{status_code}"
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
        Logger.error "ES: Error deleting data domain #{data_domain.name} status #{status_code}"
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
        Logger.error "ES: Error deleting business concept #{concept.name} status #{status_code}"
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
