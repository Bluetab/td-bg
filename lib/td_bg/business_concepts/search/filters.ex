defmodule TdBg.BusinessConcepts.Search.Filters do
  @moduledoc """
  Functions for composing search query filters.
  """

  alias TdBg.Search.Query
  alias TdCache.TaxonomyCache

  def build_filters(filters, aggs \\ %{}) do
    Enum.map(filters, &build_filter(&1, aggs))
  end

  defp build_filter({"taxonomy" = key, values}, aggs) do
    values = TaxonomyCache.reachable_domain_ids(values)
    build_filter(key, values, aggs)
  end

  defp build_filter({key, values}, aggs) do
    build_filter(key, values, aggs)
  end

  defp build_filter(%{terms: %{field: field}}, values) do
    term(field, values)
  end

  defp build_filter(
         %{
           nested: %{path: path},
           aggs: %{distinct_search: %{terms: %{field: field}}}
         },
         values
       ) do
    %{nested: %{path: path, query: term(field, values)}}
  end

  defp build_filter(field, values) when is_binary(field) do
    term(field, values)
  end

  defp build_filter(key, values, aggs) do
    aggs
    |> Map.get(key, _field = key)
    |> build_filter(values)
  end

  defp term(field, values) do
    Query.term(field, values)
  end
end
