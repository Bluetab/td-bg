defmodule TdBg.Metrics.Instrumenter do
  @moduledoc """
  Prometheus instrumentation for Business Glossary metrics.
  """

  alias Prometheus.Metric.Gauge
  alias Prometheus.Registry
  alias TdBg.Metrics.Dimensions
  alias TdCache.TemplateCache

  require Registry
  require Gauge

  @metrics %{
    count: %{
      name: "bg_concepts_count",
      help: "Business Concepts Versions Counter",
      labels: [:has_link, :has_rule, :parent_domains, :status]
    },
    completeness_total: %{
      name: "bg_completeness_total",
      help: "Business Glossary Total Optional Fields",
      labels: [:field, :group, :parent_domains, :status]
    },
    completeness_completed: %{
      name: "bg_completeness_completed",
      help: "Business Glossary Completed Optional Fields",
      labels: [:field, :group, :parent_domains, :status]
    }
  }

  def reset do
    Registry.deregister_collector(:default, :prometheus_gauge)
    Registry.register_collector(:default, :prometheus_gauge)

    template_names()
    |> Enum.each(&declare_gauges/1)
  end

  def set_count(%{count: count, dimensions: dimensions, template_name: template_name}) do
    set_gauge(:count, template_name, dimensions, count)
  end

  def set_completeness(%{
        completed: completed,
        total: total,
        dimensions: dimensions,
        template_name: template_name
      }) do
    set_gauge(:completeness_completed, template_name, dimensions, completed)
    set_gauge(:completeness_total, template_name, dimensions, total)
  end

  defp set_gauge(metric, template_name, dimensions, value) do
    metric_name = metric_name(metric, template_name)
    labels = sorted_dimensions(dimensions)
    Gauge.set([name: metric_name, labels: labels], value)
  end

  defp metric_name(metric, template_name) do
    case Map.get(@metrics, metric) do
      %{name: name} -> normalized_metric_name(name, template_name)
    end
  end

  defp normalized_metric_name(metric_name, template_name) do
    [metric_name, normalize(template_name)]
    |> Enum.join("_")
    |> String.to_atom()
  end

  defp sorted_dimensions(%{} = dimensions) do
    dimensions
    |> Enum.sort_by(&elem(&1, 0))
    |> Enum.map(&elem(&1, 1))
    |> Enum.map(&to_string/1)
    |> Enum.map(&String.to_atom/1)
  end

  defp template_names do
    template_names =
      "bg"
      |> TemplateCache.list_by_scope!()
      |> Enum.map(& &1.name)

    [Dimensions.missing_dimension() | template_names]
  end

  defp declare_gauges(template_name) do
    [:count, :completeness_total, :completeness_completed]
    |> Enum.map(&gauge(&1, template_name))
    |> Enum.each(&Gauge.declare/1)
  end

  defp gauge(metric, template_name) do
    case Map.get(@metrics, metric) do
      %{name: metric_name, help: help, labels: labels} ->
        [
          name: normalized_metric_name(metric_name, template_name),
          help: help,
          labels: labels
        ]
    end
  end

  defp normalize(template_name) do
    template_name
    |> String.replace(~r/[^A-z\s]/u, "")
    |> String.replace(~r/\s+/, "_")
  end
end
