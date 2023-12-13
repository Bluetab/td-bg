defmodule TdBg.BusinessConcepts.Search.Query do
  @moduledoc """
  Support for building business concept search queries.
  """

  import TdCore.Search.Query,
    only: [term_or_terms: 2, must: 2, must_not: 2, should: 2, bool_query: 1]

  alias TdBg.BusinessConcepts.BusinessConceptVersion
  alias TdBg.BusinessConcepts.Search.Filters
  alias TdCore.Search.ElasticDocumentProtocol

  @match_all %{match_all: %{}}
  @match_none %{match_none: %{}}

  @permissions_to_status %{
    "view_draft_business_concepts" => "draft",
    "view_deprecated_business_concepts" => "deprecated",
    "view_approval_pending_business_concepts" => "pending_approval",
    "view_published_business_concepts" => "published",
    "view_rejected_business_concepts" => "rejected",
    "view_versioned_business_concepts" => "versioned"
  }

  def build_filters(%{} = permissions, opts \\ []) do
    status_filter = status_filter(permissions)
    confidential_filter = confidential_filter(permissions)
    links_filter = if opts[:linkable], do: links_filter(permissions), else: nil

    [status_filter, confidential_filter, links_filter]
    |> Enum.flat_map(&List.wrap/1)
  end

  def status_filter(%{} = permissions) do
    @permissions_to_status
    |> Map.keys()
    |> Enum.map(&{Map.get(permissions, &1, :none), &1})
    |> Enum.group_by(
      fn {scope, _} -> scope end,
      fn {_, permission} -> Map.get(@permissions_to_status, permission) end
    )
    |> do_status_filter()
  end

  defp do_status_filter(%{} = permissions_by_scope) when map_size(permissions_by_scope) <= 1 do
    case Enum.at(permissions_by_scope, 0) do
      nil ->
        @match_none

      {:none, _statuses} ->
        @match_none

      {:all, _statuses} ->
        @match_all

      {domain_ids, statuses} ->
        [
          term_or_terms("status", statuses),
          term_or_terms("domain_ids", domain_ids)
        ]
    end
  end

  defp do_status_filter(permissions_by_scope) when map_size(permissions_by_scope) > 1 do
    permissions_by_scope
    # :all < list < :none
    |> Enum.sort_by(fn
      {:all, _} -> 1
      {:none, _} -> 3
      _list -> 2
    end)
    |> Enum.reduce(%{}, fn
      {:all, statuses}, acc ->
        should(acc, term_or_terms("status", statuses))

      {:none, _statuses}, acc when map_size(acc) > 0 ->
        # We can avoid a must_not clause if any other status clause exists
        acc

      {:none, statuses}, acc ->
        must_not(acc, term_or_terms("status", statuses))

      {domain_ids, statuses}, acc ->
        bool = %{
          filter: [
            term_or_terms("status", statuses),
            term_or_terms("domain_ids", domain_ids)
          ]
        }

        should(acc, %{bool: bool})
    end)
    |> maybe_bool_query()
  end

  def confidential_filter(%{} = permissions) do
    permissions
    |> Map.get("manage_confidential_business_concepts", :none)
    |> do_confidential_filter()
  end

  defp do_confidential_filter(:all), do: nil

  defp do_confidential_filter(:none),
    do: %{bool: %{must_not: [%{term: %{"confidential.raw" => true}}]}}

  defp do_confidential_filter(domain_ids) when is_list(domain_ids) do
    %{
      bool: %{
        should: [
          term_or_terms("domain_ids", domain_ids),
          do_confidential_filter(:none)
        ]
      }
    }
  end

  def links_filter(%{} = permissions) do
    permissions
    |> Map.get("manage_business_concept_links", :none)
    |> do_links_filter()
  end

  defp do_links_filter(:all), do: nil
  defp do_links_filter(:none), do: %{match_none: %{}}

  defp do_links_filter(domain_ids) when is_list(domain_ids) do
    term_or_terms("domain_ids", domain_ids)
  end

  defp maybe_bool_query(%{should: [single_clause]} = bool) when map_size(bool) == 1,
    do: single_clause

  defp maybe_bool_query(%{} = bool) when map_size(bool) >= 1, do: %{bool: bool}

  def build_query(filters, %{"must" => _} = params) do
    query = Map.get(params, "query")

    params
    |> Map.take(["must", "query"])
    |> Enum.reduce(%{must: filters}, &reduce_query/2)
    |> add_query_should(query)
    |> bool_query()
  end

  def build_query(filters, params) do
    params
    |> Map.take(["filters", "query"])
    |> Enum.reduce(%{filter: filters}, &reduce_query/2)
    |> bool_query()
  end

  defp add_query_should(filters, nil), do: filters

  defp add_query_should(filters, query) do
    should = [
      %{
        multi_match: %{
          query: maybe_wildcard(query),
          type: "best_fields",
          operator: "and"
        }
      }
    ]

    Map.put(filters, :should, should)
  end

  defp reduce_query({"filters", %{} = user_filters}, %{filter: filters} = acc)
       when map_size(user_filters) > 0 do
    %{acc | filter: merge_filters(filters, user_filters)}
  end

  defp reduce_query({"filters", %{}}, %{} = acc) do
    acc
  end

  defp reduce_query({"must", %{} = user_filters}, %{must: filters} = acc)
       when map_size(user_filters) > 0 do
    %{acc | must: merge_filters(filters, user_filters)}
  end

  defp reduce_query({"must", %{}}, %{} = acc) do
    acc
  end

  defp reduce_query({"query", query}, acc) do
    must(acc, %{simple_query_string: %{query: maybe_wildcard(query)}})
  end

  defp merge_filters(filters, user_filters) do
    aggs = ElasticDocumentProtocol.aggregations(%BusinessConceptVersion{})

    case Enum.uniq(filters ++ Filters.build_filters(user_filters, aggs)) do
      [_, _ | _] = filters -> Enum.reject(filters, &(&1 == %{match_all: %{}}))
      filters -> filters
    end
  end

  defp maybe_wildcard(query) do
    case String.last(query) do
      nil -> query
      "\"" -> query
      ")" -> query
      " " -> query
      _ -> "#{query}*"
    end
  end
end
