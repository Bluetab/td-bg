defmodule TdBg.Search.MockSearch do
  @moduledoc false

  alias Poison
  alias TdBg.BusinessConcepts
  alias TdBg.BusinessConcepts.BusinessConceptVersion

  def put_search(_something) do
  end

  def delete_search(_something) do
  end

  def search("business_concept", %{query: %{bool: %{must: %{match_all: %{}}}}}) do
    BusinessConcepts.list_all_business_concept_versions()
    |> Enum.map(&BusinessConceptVersion.search_fields(&1))
    |> Enum.map(&%{_source: &1})
    |> Poison.encode!()
    |> Poison.decode!()
    |> search_results
  end

  def search("business_concept", %{query: %{term: %{business_concept_id: business_concept_id}}}) do
    BusinessConcepts.list_all_business_concept_versions()
    |> Enum.filter(&(&1.business_concept_id == business_concept_id))
    |> Enum.map(&BusinessConceptVersion.search_fields(&1))
    |> Enum.map(&%{_source: &1})
    |> Poison.encode!()
    |> Poison.decode!()
    |> search_results
  end

  def search("business_concept", %{
        query: %{bool: %{must: %{simple_query_string: %{query: query}}}}
      }) do
    BusinessConcepts.list_all_business_concept_versions()
    |> Enum.map(&BusinessConceptVersion.search_fields(&1))
    |> Enum.filter(&matches(&1, query))
    |> Enum.map(&%{_source: &1})
    |> Poison.encode!()
    |> Poison.decode!()
    |> search_results
  end

  def search("business_concept", %{
    query: _query,
    sort: _sort,
    size: _size
  }) do
    default_params_map = %{:link_count => 0, :q_rule_count => 0}
    BusinessConcepts.list_all_business_concept_versions()
      |> Enum.map(&BusinessConceptVersion.search_fields(&1))
      |> Enum.map(fn(bv) -> Map.merge(bv, default_params_map, fn _k, v1, v2 -> v1 || v2 end) end)
      |> search_results
  end

  defp search_results(results) do
    %{results: results, total: Enum.count(results)}
  end

  defp matches(string, query) when is_bitstring(string) do
    prefix = String.replace(query, "*", "")
    String.starts_with?(string, prefix)
  end

  defp matches(list, query) when is_list(list) do
    list |> Enum.any?(&matches(&1, query))
  end

  defp matches(map, query) when is_map(map) do
    map |> Map.values() |> matches(query)
  end

  defp matches(_item, _query), do: false

  def get_filters(_query) do
    %{
      "domain" => ["Domain 1", "Domain 2"],
      "dynamic_field" => ["Value 1", "Value 2"]
    }
  end
end
