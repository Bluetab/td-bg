defmodule TdBg.BusinessConcept.Search do
  @moduledoc """
  Helper module to construct business concept search queries.
  """
  alias TdBg.Auth.Claims
  alias TdBg.BusinessConcept.Query
  alias TdBg.Permissions
  alias TdBg.Search
  alias TdBg.Search.Aggregations

  @map_field_to_condition %{
    "rule_terms" => %{gt: 0},
    "linked_terms" => %{gt: 0},
    "not_linked_terms" => %{gte: 0, lt: 1},
    "not_rule_terms" => %{gte: 0, lt: 1}
  }

  @permissions_to_status %{
    view_approval_pending_business_concepts: "pending_approval",
    view_deprecated_business_concepts: "deprecated",
    view_draft_business_concepts: "draft",
    view_published_business_concepts: "published",
    view_rejected_business_concepts: "rejected",
    view_versioned_business_concepts: "versioned"
  }

  def get_filter_values(%Claims{role: "admin"}, params) do
    filter_clause = create_filters(params)
    query = create_query(%{}, filter_clause)
    search = %{query: query, aggs: Aggregations.aggregation_terms()}
    Search.get_filters(search)
  end

  def get_filter_values(%Claims{} = claims, params) do
    permissions = get_permissions(params, claims)
    get_filter_values(permissions, params)
  end

  def get_filter_values([], _), do: %{}

  def get_filter_values(permissions, params) do
    filter_clause = create_filters(params)
    filter = create_filter_clause(permissions, filter_clause)
    query = create_query(%{}, filter)
    search = %{query: query, aggs: Aggregations.aggregation_terms()}
    Search.get_filters(search)
  end

  def search_business_concept_versions(params, claims, page \\ 0, size \\ 50)

  # Admin user or service account search, no filters applied
  def search_business_concept_versions(params, %Claims{role: role}, page, size)
      when role in ["admin", "service"] do

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
    |> do_search()
  end

  # Non-admin user search, filters applied
  def search_business_concept_versions(params, %Claims{} = claims, page, size) do
    permissions = get_permissions(params, claims)
    filter_business_concept_versions(params, permissions, page, size)
  end

  def get_permissions(%{"only_linkable" => true}, claims) do
    claims
    |> Permissions.get_domain_permissions()
    |> Enum.filter(
      &(&1
        |> Map.get(:permissions)
        |> Enum.member?(:manage_business_concept_links))
    )
  end

  def get_permissions(_, claims), do: Permissions.get_domain_permissions(claims)

  def list_business_concept_versions(business_concept_id, %Claims{role: role})
      when role in ["admin", "service"] do
    query = create_query(%{business_concept_id: business_concept_id})

    %{query: query}
    |> do_search()
  end

  def list_business_concept_versions(business_concept_id, %Claims{} = claims) do
    permissions = Permissions.get_domain_permissions(claims)
    predefined_query = %{business_concept_id: business_concept_id} |> create_query
    filter = create_filter_clause(permissions, [predefined_query])
    query = create_query(nil, filter)

    %{query: query}
    |> do_search()
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
    %{terms: %{field => values}}
    |> bool_query()
  end

  defp create_range(_filter, []), do: []

  defp create_range(filter, values) do
    %{filter => buid_range_condition(values)}
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
    filter = create_filter_clause(permissions, user_defined_filters)
    query = create_query(params, filter)
    sort = Map.get(params, "sort", ["_score", "name.raw"])

    %{from: page * size, size: size, query: query, sort: sort}
    |> do_search()
  end

  def get_business_concepts_from_domain(resource_filter, page, size) do
    filter = create_filter_clause(resource_filter)
    query = create_query(resource_filter, filter)

    %{from: page * size, size: size, query: query}
    |> do_search()
  end

  def get_business_concepts_from_query(query, page, size) do
    %{from: page * size, size: size, query: query}
    |> do_search()
  end

  defp create_query(%{business_concept_id: id}) do
    %{term: %{business_concept_id: id}}
  end

  defp create_query(%{"query" => query}) do
    equery = Query.add_query_wildcard(query)

    %{simple_query_string: %{query: equery}}
    |> bool_query()
  end

  defp create_query(_params) do
    %{match_all: %{}}
    |> bool_query()
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
    should_clause = Enum.map(permissions, &entry_to_filter_clause(&1, user_defined_filters))

    %{bool: %{should: should_clause}}
  end

  defp create_filter_clause(resource_filter) do
    should_clause = entry_to_filter_clause(resource_filter)
    %{bool: %{should: should_clause}}
  end

  defp entry_to_filter_clause(
         %{resource_id: resource_id, permissions: permissions},
         user_defined_filters
       ) do
    domain_clause = %{term: %{domain_ids: resource_id}}

    status =
      @permissions_to_status
      |> Map.take(permissions)
      |> Map.values()

    status_clause = %{terms: %{status: status}}

    confidential_clause =
      case Enum.member?(permissions, :manage_confidential_business_concepts) do
        true -> %{terms: %{"confidential.raw": [true, false]}}
        false -> %{terms: %{"confidential.raw": [false]}}
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
    %{results: results, total: total} = Search.search(search)
    results = Enum.map(results, &Map.get(&1, "_source"))
    %{results: results, total: total}
  end
end
