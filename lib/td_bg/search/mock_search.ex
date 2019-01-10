defmodule TdBg.Search.MockSearch do
  @moduledoc false

  alias Poison
  alias TdBg.BusinessConcepts
  alias TdBg.BusinessConcepts.BusinessConceptVersion

  def put_search(_something) do
  end

  def delete_search(_something) do
  end

  def put_bulk_search(_something, _something_else) do
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
    default_params_map = %{:link_count => 0, :rule_count => 0}
    BusinessConcepts.list_all_business_concept_versions()
      |> Enum.map(&BusinessConceptVersion.search_fields(&1))
      |> Enum.map(fn(bv) -> Map.merge(bv, default_params_map, fn _k, v1, v2 -> v1 || v2 end) end)
      |> search_results
  end

  def search("business_concept", %{
      query: %{
        bool: %{
          must_not: %{
            term: %{status: status}
          },
          must: %{
            query_string: %{
              query: query
            }
          },
          filter: [%{term: %{current: current}}, %{term: %{domain_ids: domain_id}}]
        }
      }
    }) do

      user_name =
        query
        |> String.split(":(\"")
        |> List.last()
        |> String.split("\")")
        |> List.first()
        |> String.downcase()

      BusinessConcepts.list_all_business_concept_versions()
      |> Enum.filter(&(Map.get(&1, :current) == current))
      |> Enum.filter(&(Map.get(&1, :status) != status))
      |> Enum.filter(fn v ->
        c_domain_id =
          v
          |> Map.get(:business_concept)
          |> Map.get(:domain_id)
          |> Integer.to_string()

        c_domain_id == domain_id
      end)
      |> Enum.filter(fn v ->
          v
          |> Map.get(:content)
          |> Map.values()
          |> Enum.any?(&(String.downcase(&1) == user_name))
      end)
      |> search_results()
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
