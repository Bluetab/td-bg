defmodule TdBg.Search.Aggregations do
  @moduledoc """
  Aggregations for elasticsearch
  """

  alias TdCache.TemplateCache
  alias TdDfLib.Format

  def aggregation_terms do
    static_keywords = [
      {"current", %{terms: %{field: "current"}}},
      {"shared_to_names", %{terms: %{field: "shared_to_names.raw"}}},
      {"domain_ids", %{terms: %{field: "domain_ids"}}},
      {"status", %{terms: %{field: "status"}}},
      {"confidential.raw", %{terms: %{field: "confidential.raw"}}},
      {"template", %{terms: %{field: "template.label.raw", size: 50}}},
      {"rule_count",
       %{terms: %{script: "doc['rule_count'].value > 0 ? 'rule_terms' : 'not_rule_terms'"}}},
      {"link_count",
       %{terms: %{script: "doc['link_count'].value > 0 ? 'linked_terms' : 'not_linked_terms'"}}},
      {"taxonomy",
       %{
         nested: %{path: "domain_parents"},
         aggs: %{distinct_search: %{terms: %{field: "domain_parents.id", size: 50}}}
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
end
