defmodule TdBg.Search.Aggregations do
  @moduledoc """
  Aggregations for elasticsearch
  """

  alias TdCache.TemplateCache

  def aggregation_terms do
    static_keywords = [
      {"domain", %{terms: %{field: "domain.name.raw", size: 50}}},
      {"domain_id", %{terms: %{field: "domain.id"}}},
      {"business_concept_id", %{terms: %{field: "business_concept_id"}}},
      {"domain_parents",
       %{
         nested: %{path: "domain_parents"},
         aggs: %{distinct_search: %{terms: %{field: "domain_parents.name.raw", size: 50}}}
       }},
      {"status", %{terms: %{field: "status"}}},
      {"current", %{terms: %{field: "current"}}},
      {"in_progress", %{terms: %{field: "in_progress"}}},
      {"template", %{terms: %{field: "template.label.raw", size: 50}}},
      {"rule_count",
       %{terms: %{script: "doc['rule_count'].value > 0 ? 'rule_terms' : 'not_rule_terms'"}}},
      {"link_count",
       %{terms: %{script: "doc['link_count'].value > 0 ? 'linked_terms' : 'not_linked_terms'"}}}
    ]

    dynamic_keywords =
      TemplateCache.list_by_scope!("bg")
      |> Enum.flat_map(&template_terms/1)

    (static_keywords ++ dynamic_keywords)
    |> Enum.into(%{})
  end

  defp template_terms(%{content: content}) do
    content
    |> Enum.filter(&filter_content_term/1)
    |> Enum.map(&Map.take(&1, ["name", "type"]))
    |> Enum.map(&content_term/1)
  end

  defp filter_content_term(%{"name" => "_confidential"}), do: true
  defp filter_content_term(%{"values" => values}) when is_map(values), do: true
  defp filter_content_term(_), do: false

  defp content_term(%{"name" => field, "type" => "user"}) do
    {field, %{terms: %{field: "content.#{field}.raw", size: 50}}}
  end

  defp content_term(%{"name" => field}) do
    {field, %{terms: %{field: "content.#{field}.raw"}}}
  end
end
