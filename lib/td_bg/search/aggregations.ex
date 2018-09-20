defmodule TdBg.Search.Aggregations do
  @moduledoc """
    Aggregations for elasticsearch
  """
  alias TdBg.Templates
  alias TdBg.Templates.Template

  def aggregation_terms do
    static_keywords = [
      {"domain", %{terms: %{field: "domain.name.raw", size: 50}}},
      {"domain_id", %{terms: %{field: "domain.id"}}},
      {"status", %{terms: %{field: "status"}}},
      {"current", %{terms: %{field: "current"}}},
      {"type", %{terms: %{field: "type"}}},
      {"q_rule_count", %{terms: %{script: "doc['q_rule_count'].value > 0 ? 'q_rule_terms' : 'not_q_rule_terms'"}}},
      {"link_count", %{terms: %{script: "doc['link_count'].value > 0 ? 'linked_terms' : 'not_linked_terms'"}}}
    ]

    dynamic_keywords =
      Templates.list_templates()
      |> Enum.flat_map(&template_terms/1)

    (static_keywords ++ dynamic_keywords)
    |> Enum.into(%{})
  end

  def template_terms(%Template{content: content}) do
    content
    |> Enum.filter(&(&1["type"] == "list"))
    |> Enum.map(& &1["name"])
    |> Enum.map(&content_term/1)
  end

  defp content_term(field) do
    {field, %{terms: %{field: "content.#{field}.raw"}}}
  end
end
