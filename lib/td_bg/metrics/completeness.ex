defmodule TdBg.Metrics.Completeness do
  @moduledoc """
  Business Glossary Completeness Metrics calculation
  """

  alias TdBg.Metrics.Dimensions
  alias TdDfLib.Templates

  def transform(%{results: results}) do
    results
    |> Enum.map(&Dimensions.add_dimensions(&1, ["parent_domains", "template_name"]))
    |> Enum.group_by(& &1["template_name"])
    |> Map.delete(nil)
    |> Enum.flat_map(&template_metrics/1)
  end

  defp template_metrics({template_name, concepts}) do
    fields = Templates.optional_fields(template_name)

    concepts
    |> Enum.flat_map(&concept_metrics(&1, template_name, fields))
    |> Enum.group_by(&Map.take(&1, [:dimensions, :template_name]), &Map.get(&1, :count))
    |> Enum.map(fn {dimensions, counts} ->
      dimensions
      |> Map.put(:total, Enum.count(counts))
      |> Map.put(:completed, Enum.count(counts, &(&1 == 0)))
    end)
  end

  defp concept_metrics(concept, template_name, fields) do
    Enum.map(fields, &field_metric(concept, template_name, &1))
  end

  defp field_metric(%{"content" => content} = concept, template_name, field) do
    %{
      dimensions: dimensions(concept, template_name, field),
      template_name: template_name,
      count: count(content, field)
    }
  end

  defp dimensions(concept, template_name, field) do
    concept
    |> Map.take(["status", "parent_domains"])
    |> Map.put("field", field)
    |> put_group(Templates.group_name(template_name, field))
  end

  defp put_group(%{} = dimensions, nil), do: dimensions
  defp put_group(%{} = dimensions, group), do: Map.put(dimensions, "group", group)

  defp count(%{} = content, field) do
    content
    |> Map.get(field)
    |> count()
  end

  defp count(nil), do: 0
  defp count(""), do: 0
  defp count(_), do: 1
end
