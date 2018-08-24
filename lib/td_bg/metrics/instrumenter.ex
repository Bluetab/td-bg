defmodule TdBg.Metrics.Instrumenter do
  @moduledoc false

  use Prometheus.Metric

  alias TdBg.Metrics.BusinessConcepts

  def setup do
    BusinessConcepts.get_dimensions_from_templates()
    |> Enum.each(fn(template) ->

      Gauge.declare([
        name: String.to_atom("bg_concepts_count_" <> "#{template.name |> BusinessConcepts.normalize_template_name()}"),
        help: "Business Concepts Versions Counter",
        labels: Enum.sort([:status, :domain0, :domain1, :has_quality, :has_link] ++ template.dimensions)
      ])
      Gauge.declare([
        name: String.to_atom("bg_concept_completness_" <> "#{template.name |> BusinessConcepts.normalize_template_name()}"),
        help: "Business Concepts Versions Completness",
        labels: Enum.sort([:id, :field, :group, :status, :domain0, :domain1] ++ template.dimensions)
      ])
    end)
  end

  def set_concepts_count(%{count: count, dimensions: dimensions, template_name: template_name}) do
    dimensions = format_domain_parents_field(dimensions)
    Gauge.set([name: String.to_atom("bg_concepts_count_" <> "#{template_name}"), labels: dimensions], count)
  end

  def set_concept_fields_completness(%{count: count, dimensions: dimensions, template_name: template_name}) do
    dimensions = format_domain_parents_field(dimensions)
    Gauge.set([name: String.to_atom("bg_concept_completness_" <> "#{template_name}"), labels: dimensions], count)
  end

  defp format_domain_parents_field(dimensions) do
    dimensions
    |> Map.update!(:domain_parents, fn(current) ->
      case length(current) do
        1 -> current ++ [""]
        _ -> current
      end
    end)
    |> Map.values() |> List.flatten |> Enum.map(&to_string(&1)) |> Enum.map(&String.to_atom(&1))
  end

end
