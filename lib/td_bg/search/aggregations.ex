defmodule TdBg.Search.Aggregations do
  @moduledoc """
    Aggregations for elasticsearch
  """

  @df_cache Application.get_env(:td_bg, :df_cache)

  def aggregation_terms do
    static_keywords = [
      {"domain", %{terms: %{field: "domain.name.raw", size: 50}}},
      {"domain_id", %{terms: %{field: "domain.id"}}},
      {"business_concept_id", %{terms: %{field: "business_concept_id"}}},
      {"status", %{terms: %{field: "status"}}},
      {"current", %{terms: %{field: "current"}}},
      {"in_progress", %{terms: %{field: "in_progress"}}},
      {"template", %{terms: %{field: "template.label.raw", size: 50}}},
      {"rule_count", %{terms: %{script: "doc['rule_count'].value > 0 ? 'rule_terms' : 'not_rule_terms'"}}},
      {"link_count", %{terms: %{script: "doc['link_count'].value > 0 ? 'linked_terms' : 'not_linked_terms'"}}}
    ]

    dynamic_keywords =
      @df_cache.list_templates()
      |> Enum.flat_map(&template_terms/1)

    (static_keywords ++ dynamic_keywords)
    |> Enum.into(%{})
  end

  def template_terms(%{content: content}) do
    content
    |> Enum.filter(&filter_content_term/1)
    |> Enum.map(& &1["name"])
    |> Enum.map(&content_term/1)
  end

  def filter_content_term(%{"name" => "_confidential"}), do: true
  def filter_content_term(%{"type" => "list"}), do: true
  def filter_content_term(_), do: false

  defp content_term(field) do
    {field, %{terms: %{field: "content.#{field}.raw"}}}
  end
end
