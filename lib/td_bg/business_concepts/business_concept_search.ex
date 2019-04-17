defmodule TdBg.BusinessConcept.Search do
  @moduledoc """
    Helper module to construct business concept search queries.
  """
  alias TdBg.Accounts.User
  alias TdBg.BusinessConcept.Query
  alias TdBg.BusinessConcepts.BusinessConcept
  alias TdBg.Permissions
  alias TdBg.Search.Aggregations

  @search_service Application.get_env(:td_bg, :elasticsearch)[:search_service]
  @map_field_to_condition %{
    "rule_terms" => %{gt: 0},
    "linked_terms" => %{gt: 0},
    "not_linked_terms" => %{gte: 0, lt: 1},
    "not_rule_terms" => %{gte: 0, lt: 1}
  }

  def get_filter_values(%User{is_admin: true}, params) do
    filter_clause = create_filters(params)
    query = %{} |> create_query(filter_clause)
    search = %{query: query, aggs: Aggregations.aggregation_terms()}
    @search_service.get_filters(search)
  end

  def get_filter_values(%User{} = user, params) do
    permissions = get_permissions(params, user)
    get_filter_values(permissions, params)
  end

  def get_filter_values([], _), do: %{}

  def get_filter_values(permissions, params) do
    filter_clause = create_filters(params)
    filter = permissions |> create_filter_clause(filter_clause)
    query = %{} |> create_query(filter)
    search = %{query: query, aggs: Aggregations.aggregation_terms()}
    @search_service.get_filters(search)
  end

  def search_business_concept_versions(params, user, page \\ 0, size \\ 50)

  # Admin user search, no filters applied
  def search_business_concept_versions(params, %User{is_admin: true}, page, size) do
    filter_clause = create_filters(params)

    query =
      case filter_clause do
        [] -> create_query(params)
        _ -> create_query(params, filter_clause)
      end

    sort = Map.get(params, "sort", ["_score", "name.raw"])

    %{
      from: page * size,
      size: size,
      query: query,
      sort: sort,
      aggs: Aggregations.aggregation_terms()
    }
    |> do_search
  end

  # Non-admin user search, filters applied
  def search_business_concept_versions(params, %User{} = user, page, size) do
    permissions = get_permissions(params, user)
    filter_business_concept_versions(params, permissions, page, size)
  end

  defp get_permissions(%{"only_linkable" => true}, user) do
    user
    |> Permissions.get_domain_permissions()
    |> Enum.filter(
      &(&1
        |> Map.get(:permissions)
        |> Enum.member?(:manage_business_concept_links))
    )
  end

  defp get_permissions(_, user), do: Permissions.get_domain_permissions(user)

  def list_business_concept_versions(business_concept_id, %User{is_admin: true}) do
    query = %{business_concept_id: business_concept_id} |> create_query

    %{query: query}
    |> do_search
  end

  def list_business_concept_versions(business_concept_id, %User{} = user) do
    permissions = user |> Permissions.get_domain_permissions()
    predefined_query = %{business_concept_id: business_concept_id} |> create_query
    filter = permissions |> create_filter_clause([predefined_query])
    query = create_query(nil, filter)

    %{query: query}
    |> do_search
  end

  defp create_filters(%{"filters" => filters}) do
    filters
    |> Map.to_list()
    |> Enum.map(&to_terms_query/1)
  end

  defp create_filters(_), do: []

  defp to_terms_query({filter, values}) do
    Aggregations.aggregation_terms()
    |> Map.get(filter)
    |> get_filter(values, filter)
  end

  defp get_filter(%{terms: %{field: field}}, values, _) do
    %{terms: %{field => values}}
  end

  defp get_filter(%{terms: %{script: _}}, values, filter) do
    %{range: create_range(filter, values)}
  end

  defp get_filter(%{aggs: %{distinct_search: distinct_search}, nested: %{path: path}}, values, _) do
    %{nested: %{path: path, query: build_nested_query(distinct_search, values)}}
  end

  defp build_nested_query(%{terms: %{field: field}}, values) do
    %{terms: %{field => values}} |> bool_query()
  end

  defp create_range(_filter, []), do: []

  defp create_range(filter, values) do
    Map.new()
    |> Map.put_new(filter, buid_range_condition(values))
  end

  defp buid_range_condition(values) do
    case length(values) do
      1 -> get_param_condition(values)
      2 -> %{gte: 0}
      _ -> %{}
    end
  end

  defp get_param_condition([head | _tail]) do
    Map.fetch!(@map_field_to_condition, head)
  end

  defp filter_business_concept_versions(_params, [], _page, _size), do: %{results: [], total: 0}

  defp filter_business_concept_versions(params, [_h | _t] = permissions, page, size) do
    user_defined_filters = create_filters(params)

    filter = permissions |> create_filter_clause(user_defined_filters)

    query = create_query(params, filter)
    sort = Map.get(params, "sort", ["_score", "name.raw"])

    %{from: page * size, size: size, query: query, sort: sort}
    |> do_search
  end

  def get_business_concepts_from_domain(resource_filter, page, size) do
    filter = resource_filter |> create_filter_clause()

    query = create_query(resource_filter, filter)

    %{from: page * size, size: size, query: query}
    |> do_search
  end

  def get_business_concepts_from_query(query, page, size) do
    %{from: page * size, size: size, query: query}
    |> do_search
  end

  defp create_query(%{business_concept_id: id}) do
    %{term: %{business_concept_id: id}}
  end

  defp create_query(%{"query" => query}) do
    equery = Query.add_query_wildcard(query)

    %{simple_query_string: %{query: equery}}
    |> bool_query
  end

  defp create_query(_params) do
    %{match_all: %{}}
    |> bool_query
  end

  defp create_query(%{"query" => query}, filter) do
    equery = Query.add_query_wildcard(query)

    %{simple_query_string: %{query: equery}}
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

  defp create_filter_clause(permissions, user_defined_filters) do
    should_clause =
      permissions
      |> Enum.map(&entry_to_filter_clause(&1, user_defined_filters))

    %{bool: %{should: should_clause}}
  end

  defp create_filter_clause(resource_filter) do
    should_clause = resource_filter |> entry_to_filter_clause()
    %{bool: %{should: should_clause}}
  end

  defp entry_to_filter_clause(
         %{resource_id: resource_id, permissions: permissions},
         user_defined_filters
       ) do
    domain_clause = %{term: %{domain_ids: resource_id}}

    status =
      permissions
      |> Enum.map(&Map.get(BusinessConcept.permissions_to_status(), &1))
      |> Enum.filter(&(!is_nil(&1)))

    status_clause = %{terms: %{status: status}}

    confidential_clause =
      case Enum.member?(permissions, :manage_confidential_business_concepts) do
        true -> %{terms: %{"content._confidential.raw": ["Si", "No"]}}
        false -> %{terms: %{"content._confidential.raw": ["No"]}}
      end

    %{
      bool: %{filter: user_defined_filters ++ [domain_clause, status_clause, confidential_clause]}
    }
  end

  defp entry_to_filter_clause(%{resource_id: resource_id}) do
    domain_clause = %{term: %{domain_ids: resource_id}}
    %{bool: %{filter: [domain_clause]}}
  end

  defp do_search(search) do
    %{results: results, total: total} = @search_service.search("business_concept", search)
    results = results |> Enum.map(&Map.get(&1, "_source"))
    %{results: results, total: total}
  end
end
