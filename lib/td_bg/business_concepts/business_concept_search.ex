defmodule TdBg.BusinessConcept.Search do
  @moduledoc """
    Helper module to construct business concept search queries.
  """
  alias TdBg.BusinessConcepts.BusinessConcept
  alias TdBg.Permissions
  alias TdBg.Search.Aggregations

  @search_service Application.get_env(:td_bg, :elasticsearch)[:search_service]

  def get_filter_values(%{is_admin: true}) do
    query = %{} |> create_query
    search = %{query: query, aggs: Aggregations.aggregation_terms()}
    @search_service.get_filters(search)
  end

  def get_filter_values(%{id: user_id}) do
    permissions = %{user_id: user_id} |> Permissions.get_domain_permissions()
    get_filter_values(permissions)
  end

  def get_filter_values([]), do: %{}

  def get_filter_values(permissions) do
    filter = permissions |> create_filter_clause
    query = %{} |> create_query(filter)
    search = %{query: query, aggs: Aggregations.aggregation_terms()}
    @search_service.get_filters(search)
  end

  def search_business_concept_versions(params, user, page \\ 0, size \\ 50)

  # Admin user search, no filters applied
  def search_business_concept_versions(params, %{is_admin: true}, page, size) do
    filter_clause = create_filters(params)

    query =
      case filter_clause do
        [] -> create_query(params)
        _ -> create_query(params, filter_clause)
      end

     search = %{
      from: page * size,
      size: size,
      query: query,
      aggs: Aggregations.aggregation_terms()
    }

    @search_service.search("business_concept", search)
    |> Enum.map(&Map.get(&1, "_source"))
  end

  # Non-admin user search, filters applied
  def search_business_concept_versions(params, %{id: user_id}, page, size) do
    permissions = %{user_id: user_id} |> Permissions.get_domain_permissions()
    filter_business_concept_versions(params, permissions, page, size)
  end

  def create_filters(%{"filters" => filters}) do
    filters
    |> Map.to_list()
    |> Enum.map(&to_terms_query/1)
  end

  def create_filters(_), do: []

  defp to_terms_query({filter, values}) do
    field =
      Aggregations.aggregation_terms()
      |> Map.get(filter)
      |> get_filter_field

    %{terms: %{field => values}}
  end

  defp get_filter_field(%{terms: %{field: field}}) do
    field
  end

  defp filter_business_concept_versions(_params, [], _page, _size), do: []

  defp filter_business_concept_versions(params, [_h | _t] = permissions, page, size) do
    user_defined_filters = create_filters(params)
    filter = permissions |> create_filter_clause(user_defined_filters)
    query = create_query(params, filter)
    search = %{from: page * size, size: size, query: query}

    @search_service.search("business_concept", search)
    |> Enum.map(&Map.get(&1, "_source"))
  end

  defp create_query(%{"query" => query}) do
    %{simple_query_string: %{query: query}}
    |> bool_query
  end

  defp create_query(_params) do
    %{match_all: %{}}
    |> bool_query
  end

  defp create_query(%{"query" => query}, filter) do
    %{simple_query_string: %{query: query}}
    |> bool_query(filter)
  end

  defp create_query(_params, filter) do
    %{match_all: %{}}
    |> bool_query(filter)
  end

  defp bool_query(query, filter) do
    %{bool: %{must: query, filter: filter}}
  end

  defp bool_query(query) do
    %{bool: %{must: query}}
  end

  defp create_filter_clause(permissions, user_defined_filters \\ []) do
    should_clause =
      permissions
      |> Enum.map(&entry_to_filter_clause(&1, user_defined_filters))

    %{bool: %{should: should_clause}}
  end

  defp entry_to_filter_clause(
         %{resource_id: resource_id, permissions: permissions},
         user_defined_filters
       ) do
    domain_clause = %{term: %{domain_ids: resource_id}}

    status_clause =
      permissions
      |> Enum.map(&Map.get(BusinessConcept.permissions_to_status(), &1.name))
      |> Enum.filter(&(!is_nil(&1)))

    %{
      bool: %{filter: user_defined_filters ++ [domain_clause, %{terms: %{status: status_clause}}]}
    }
  end
end
