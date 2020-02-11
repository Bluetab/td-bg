defmodule TdBg.Metrics.Instrumenter do
  @moduledoc false

  use Prometheus.Metric

  alias TdBg.Metrics
  alias TdCache.TemplateCache

  require Prometheus.Registry

  def setup do
    clean_registry()

    normalized_template_names()
    |> Enum.each(fn template_name ->
      Gauge.declare(
        name: String.to_atom("bg_concepts_count_" <> template_name),
        help: "Business Concepts Versions Counter",
        labels: [:has_link, :has_rule, :parent_domains, :status]
      )

      Gauge.declare(
        name: String.to_atom("bg_completeness_completed_" <> template_name),
        help: "Business Glossary Completed Optional Fields",
        labels: [:field, :group, :parent_domains, :status]
      )

      Gauge.declare(
        name: String.to_atom("bg_completeness_total_" <> template_name),
        help: "Business Glossary Total Optional Fields",
        labels: [:field, :group, :parent_domains, :status]
      )
    end)
  end

  def set_count(%{count: count, dimensions: dimensions, template_name: template_name}) do
    dimensions = sorted_dimensions(dimensions)

    Gauge.set(
      [name: String.to_atom("bg_concepts_count_" <> "#{template_name}"), labels: dimensions],
      count
    )
  end

  def set_completeness(%{
        complete_count: completed,
        total_count: total,
        dimensions: dimensions,
        template_name: template_name
      }) do
    dimensions = sorted_dimensions(dimensions)

    Gauge.set(
      [name: String.to_atom("bg_completeness_completed_" <> template_name), labels: dimensions],
      completed
    )

    Gauge.set(
      [name: String.to_atom("bg_completeness_total_" <> template_name), labels: dimensions],
      total
    )
  end

  defp sorted_dimensions(%{} = dimensions) do
    dimensions
    |> Enum.sort_by(&elem(&1, 0))
    |> Enum.map(&elem(&1, 1))
    |> Enum.map(&to_string/1)
    |> Enum.map(&String.to_atom/1)
  end

  defp clean_registry do
    Prometheus.Registry.deregister_collector(:default, :prometheus_gauge)
    Prometheus.Registry.register_collector(:default, :prometheus_gauge)
  end

  defp normalized_template_names do
    "bg"
    |> TemplateCache.list_by_scope!()
    |> Enum.map(& &1.name)
    |> Enum.map(&Metrics.normalize_template_name/1)
    |> Enum.concat([Metrics.missing_dimension()])
  end
end
