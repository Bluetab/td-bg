defmodule TdBg.Metrics.Instrumenter do
  @moduledoc false

  use Prometheus.Metric

  alias TdBg.Metrics.BusinessConcepts
  require Prometheus.Registry

  def setup do
    clean_registry()

    BusinessConcepts.get_normalized_template_names()
    |> Enum.each(fn normalized_name ->
      Gauge.declare([
        name: String.to_atom("bg_concepts_count_" <> "#{normalized_name}"),
        help: "Business Concepts Versions Counter",
        labels: Enum.sort([:status, :parent_domains, :has_quality, :has_link])
      ])
      Gauge.declare([
        name: String.to_atom("bg_concept_completness_" <> "#{normalized_name}"),
        help: "Business Concepts Versions Completeness",
        labels: Enum.sort([:id, :field, :group, :status, :parent_domains])
      ])
    end)
  end

  def set_concepts_count(%{count: count, dimensions: dimensions, template_name: template_name}) do
    dimensions = format_domain_parents_field(dimensions)
    Gauge.set([name: String.to_atom("bg_concepts_count_" <> "#{template_name}"), labels: dimensions], count)
  end

  def set_concept_fields_completeness(%{count: count, dimensions: dimensions, template_name: template_name}) do
    dimensions = format_domain_parents_field(dimensions)
    Gauge.set([name: String.to_atom("bg_concept_completness_" <> "#{template_name}"), labels: dimensions], count)
  end

  defp format_domain_parents_field(dimensions) do
    dimensions
    |> Map.values()
    |> List.flatten
    |> Enum.map(&to_string(&1))
    |> Enum.map(&String.to_atom(&1))
  end

  defp clean_registry do
    Prometheus.Registry.deregister_collector(:default, :prometheus_gauge)
    Prometheus.Registry.register_collector(:default, :prometheus_gauge)
  end
end
