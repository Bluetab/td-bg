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
  end

  def search("business_concept", %{
    query: _query,
    sort: _sort,
    size: _size
  }) do
    %{:link_count => 0, :q_rule_count => 0}
  end

  defp matches(string, query) when is_bitstring(string) do
    String.starts_with?(string, query)
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
