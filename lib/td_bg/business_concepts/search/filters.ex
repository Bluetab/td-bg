defmodule TdBg.BusinessConcepts.Search.Filters do
  @moduledoc """
  Functions for composing search query filters.
  """

  import TdBg.Search.Query, only: [term: 2]

  def build_filters(filters, aggs \\ %{}) do
    Enum.map(filters, &build_filter(&1, aggs))
  end

  defp build_filter({filter, value_or_values}, _aggs)
       when filter in ["domain_id", "business_concept_id"] do
    term(filter, value_or_values)
  end

  defp build_filter({key, values}, aggs) do
    aggs
    |> Map.get(key)
    |> build_filter(values, key)
  end

  defp build_filter(nil, values, field) do
    term(field, values)
  end

  defp build_filter(%{terms: %{field: field}}, values, _) do
    term(field, values)
  end

  defp build_filter(%{terms: %{script: _}}, values, name) do
    %{range: create_range(name, values)}
  end

  defp build_filter(
         %{
           nested: %{path: path},
           aggs: %{distinct_search: distinct_search}
         },
         values,
         _
       ) do
    %{nested: %{path: path, query: build_nested_query(distinct_search, values)}}
  end

  defp build_nested_query(%{terms: %{field: field}}, values) do
    term(field, values)
  end

  defp create_range(_filter, []), do: []

  defp create_range("rule_count", ["rule_terms"]), do: %{"rule_count" => %{gt: 0}}
  defp create_range("rule_count", ["not_rule_terms"]), do: %{"rule_count" => %{lte: 0}}
  defp create_range("rule_count", [_, _]), do: %{"rule_count" => %{gte: 0}}

  defp create_range("link_count", ["linked_terms"]), do: %{"link_count" => %{gt: 0}}
  defp create_range("link_count", ["not_linked_terms"]), do: %{"link_count" => %{lte: 0}}
  defp create_range("link_count", [_, _]), do: %{"link_count" => %{gte: 0}}
end
