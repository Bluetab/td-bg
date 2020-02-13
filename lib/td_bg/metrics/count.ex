defmodule TdBg.Metrics.Count do
  @moduledoc """
  Business Glossary Concept Count Metrics calculation
  """

  alias TdBg.Metrics.Dimensions

  def transform(%{results: results}) do
    results
    |> Enum.map(
      &Dimensions.add_dimensions(&1, ["parent_domains", "has_rule", "has_link", "template_name"])
    )
    |> Enum.group_by(&group_fn/1, fn _ -> 1 end)
    |> Enum.map(fn {dimensions, elems} -> Map.put(dimensions, :count, Enum.count(elems)) end)
  end

  defp group_fn(%{"template_name" => template_name} = concept) do
    %{
      template_name: template_name,
      dimensions: Map.take(concept, ["status", "parent_domains", "has_rule", "has_link"])
    }
  end
end
