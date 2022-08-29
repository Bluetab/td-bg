defmodule TdBg.BusinessConcepts.Search.Aggregations do
  @moduledoc """
  Support for search aggregations
  """

  alias TdCache.TemplateCache
  alias TdDfLib.Format

  def aggregations do
    static_keywords = %{
      "confidential.raw" => %{terms: %{field: "confidential.raw"}},
      "current" => %{terms: %{field: "current"}},
      "domain_ids" => %{terms: %{field: "domain_ids"}},
      "has_rules" => %{terms: %{field: "has_rules"}},
      "link_tags" => %{terms: %{field: "link_tags"}},
      "shared_to_names" => %{terms: %{field: "shared_to_names.raw"}},
      "status" => %{terms: %{field: "status"}},
      "taxonomy" => %{terms: %{field: "domain_ids", size: 500}},
      "template" => %{terms: %{field: "template.label.raw", size: 50}}
    }

    TemplateCache.list_by_scope!("bg")
    |> Enum.flat_map(&template_terms/1)
    |> Map.new()
    |> Map.merge(static_keywords)
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

  defp content_term(%{"name" => field, "type" => "system"}) do
    {field,
     %{
       nested: %{path: "content.#{field}"},
       aggs: %{distinct_search: %{terms: %{field: "content.#{field}.external_id.raw", size: 50}}}
     }}
  end

  defp content_term(%{"name" => field, "type" => "domain"}) do
    {field, %{terms: %{field: "content.#{field}", size: 50}, meta: %{type: "domain"}}}
  end

  defp content_term(%{"name" => field}) do
    {field, %{terms: %{field: "content.#{field}.raw"}}}
  end
end
