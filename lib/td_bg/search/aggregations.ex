defmodule TdBg.Search.Aggregations do
    @moduledoc """
      Aggregations for elasticsearch
    """
    alias TdBg.Templates
    alias TdBg.Templates.Template
  
    def aggregations do
      %{aggs: aggregation_terms()}
    end
  
    def aggregation_terms do
      static_keywords = [
        {"domain", %{terms: %{field: "domain.name.raw"}}},
        {"status", %{terms: %{field: "status"}}},
        {"type", %{terms: %{field: "type"}}}
      ]
      dynamic_keywords = Templates.list_templates()
        |> Enum.flat_map(&template_terms/1)
      (static_keywords ++ dynamic_keywords)
        |> Enum.into(%{})
    end
  
    def template_terms(%Template{content: content}) do
      content
        |> Enum.filter(&(&1["type"] == "list"))
        |> Enum.map(&(&1["name"]))
        |> Enum.map(&content_term/1)
    end
  
    defp content_term(field) do
      {field, %{terms: %{field: "content.#{field}.raw"}}}
    end
  end
