defmodule TdBg.Search.Aggregations do
  @moduledoc """
  Aggregations for elasticsearch
  """

  alias TdBg.Search.Query
  alias TdBg.Taxonomies
  alias TdCache.TemplateCache
  alias TdDfLib.Format

  def aggregation_terms do
    static_keywords = [
      {"current", %{terms: %{field: "current"}}},
      {"shared_to_names", %{terms: %{field: "shared_to_names.raw"}}},
      # {"domain_id", %{terms: %{field: "domain_id"}}},
      {"domain_ids", %{terms: %{field: "domain_ids"}}},
      {"status", %{terms: %{field: "status"}}},
      {"confidential.raw", %{terms: %{field: "confidential.raw"}}},
      {"template", %{terms: %{field: "template.label.raw", size: 50}}},
      # TODO: Refactor, use boolean field instead of script
      {"rule_count",
       %{terms: %{script: "doc['rule_count'].value > 0 ? 'rule_terms' : 'not_rule_terms'"}}},
      # TODO: Refactor, use boolean field instead of script
      {"link_count",
       %{terms: %{script: "doc['link_count'].value > 0 ? 'linked_terms' : 'not_linked_terms'"}}},
      # TODO: Refactor? shouldn't need to index / aggregate parents, domain_id should be sufficient
      {"taxonomy",
       %{
         nested: %{path: "domain_parents"},
         aggs: %{
           distinct_search: %{terms: %{field: "domain_parents.id", size: get_domains_count()}}
         }
       }}
    ]

    dynamic_keywords =
      TemplateCache.list_by_scope!("bg")
      |> Enum.flat_map(&template_terms/1)

    (static_keywords ++ dynamic_keywords)
    |> Enum.into(%{})
  end

  defp template_terms(%{content: content}) do
    content
    |> Format.flatten_content_fields()
    |> Enum.filter(&filter_content_term/1)
    |> Enum.map(&Map.take(&1, ["name", "type"]))
    |> Enum.map(&content_term/1)
  end

  defp filter_content_term(%{"name" => "_confidential"}), do: true
  defp filter_content_term(%{"type" => "domain"}), do: true
  defp filter_content_term(%{"type" => "system"}), do: true
  defp filter_content_term(%{"values" => values}) when is_map(values), do: true
  defp filter_content_term(_), do: false

  defp content_term(%{"name" => field, "type" => "user"}) do
    {field, %{terms: %{field: "content.#{field}.raw", size: 50}}}
  end

  defp content_term(%{"name" => field, "type" => type}) when type in ["domain", "external_id"] do
    {field,
     %{
       nested: %{path: "content.#{field}"},
       aggs: %{distinct_search: %{terms: %{field: "content.#{field}.external_id.raw", size: 50}}}
     }}
  end

  defp content_term(%{"name" => field}) do
    {field, %{terms: %{field: "content.#{field}.raw"}}}
  end

  defp get_domains_count do
    Taxonomies.count(deleted_at: nil)
  end

  def build_filters(filters) do
    aggs = aggregation_terms()
    Enum.map(filters, &build_filter(&1, aggs))
  end

  defp build_filter({filter, value_or_values}, _aggs)
       when filter in ["domain_id", "business_concept_id"] do
    Query.term_or_terms(filter, value_or_values)
  end

  defp build_filter({filter, values}, aggs) do
    aggs
    |> Map.get(filter)
    |> build_filter(values, filter)
  end

  defp build_filter(%{terms: %{field: field}}, values, _) do
    Query.term_or_terms(field, values)
  end

  defp build_filter(%{terms: %{script: _}}, values, filter) do
    %{range: create_range(filter, values)}
  end

  defp build_filter(
         %{aggs: %{distinct_search: distinct_search}, nested: %{path: path}},
         values,
         _
       ) do
    %{nested: %{path: path, query: build_nested_query(distinct_search, values)}}
  end

  defp build_nested_query(%{terms: %{field: field}}, values) do
    %{terms: %{field => values}}
  end

  defp create_range(_filter, []), do: []

  defp create_range("rule_count", ["rule_terms"]), do: %{"rule_count" => %{gt: 0}}
  defp create_range("rule_count", ["not_rule_terms"]), do: %{"rule_count" => %{lte: 0}}
  defp create_range("rule_count", [_, _]), do: %{"rule_count" => %{gte: 0}}

  defp create_range("link_count", ["linked_terms"]), do: %{"link_count" => %{gt: 0}}
  defp create_range("link_count", ["not_linked_terms"]), do: %{"link_count" => %{lte: 0}}
  defp create_range("link_count", [_, _]), do: %{"link_count" => %{gte: 0}}
end
