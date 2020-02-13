defmodule TdBg.Metrics.Dimensions do
  @moduledoc """
  Support functions for working working with metrics dimensions.
  """

  def missing_dimension, do: "MISSING"

  def add_dimensions(%{"_source" => source}, [_ | _] = dimensions) do
    Enum.reduce(dimensions, source, &Map.put(&2, &1, get_dimension(&1, &2)))
  end

  defp get_dimension("parent_domains", %{"domain_parents" => domain_parents} = _source) do
    domain_parents
    |> Enum.map(&Map.get(&1, "name"))
    |> Enum.join(";")
  end

  defp get_dimension("template_name", %{"template" => %{"name" => template_name}}),
    do: template_name

  defp get_dimension("template_name", _source), do: missing_dimension()

  defp get_dimension("has_rule", %{"rule_count" => n} = _source) when n > 0, do: true
  defp get_dimension("has_rule", _source), do: false

  defp get_dimension("has_link", %{"link_count" => n} = _source) when n > 0, do: true
  defp get_dimension("has_link", _source), do: false
end
