defmodule TdBg.Metrics.BusinessConcepts do
  @moduledoc false

  use GenServer

  alias TdBg.Metrics.Instrumenter
  alias TdBg.Search
  alias TdBg.Utils.CollectionUtils
  alias TdCache.TemplateCache

  require Logger

  @completeness_dimensions [:id, :group, :field, :status, :parent_domains]
  @count_dimensions [:status, :parent_domains, :has_quality, :has_link]
  @metrics_publication_frequency Application.get_env(:td_bg, :metrics_publication_frequency)

  def start_link(opts \\ %{}) do
    GenServer.start_link(__MODULE__, opts)
  end

  def init(state) do
    if Application.get_env(:td_bg, :env) == :prod do
      schedule_work()
    end

    {:ok, state}
  end

  def handle_info(:work, state) do
    Instrumenter.setup()
    concepts_count_metrics = get_concepts_count()
    Logger.info("Number of concepts_count metric #{inspect(length(concepts_count_metrics))}")
    Enum.each(concepts_count_metrics, &Instrumenter.set_concepts_count/1)

    concept_fields_completeness_metrics = get_concept_fields_completeness()

    Logger.info(
      "Number of concept_fields_completeness metric #{
        inspect(length(concept_fields_completeness_metrics))
      }"
    )

    Enum.each(
      concept_fields_completeness_metrics,
      &Instrumenter.set_concept_fields_completeness(&1)
    )

    # Reschedule once more
    schedule_work()
    {:noreply, state}
  end

  defp schedule_work do
    Process.send_after(self(), :work, @metrics_publication_frequency)
  end

  def get_template_map do
    "bg"
    |> TemplateCache.list_by_scope!()
    |> Map.new(&{&1.name, get_template_dimensions(&1)})
  end

  def get_content_map do
    "bg"
    |> TemplateCache.list_by_scope!()
    |> Map.new(&{&1.name, &1.content})
  end

  defp get_template_dimensions(template), do: []

  defp not_zero(0), do: false
  defp not_zero(_), do: true

  def get_concepts_count do
    search = %{
      query: %{bool: %{must: %{match_all: %{}}}},
      size: 10_000
    }

    search
    |> Search.search()
    |> Map.get(:results)
    |> atomize_concept_map()
    |> Enum.map(&Map.update!(&1, :rule_count, &not_zero/1))
    |> Enum.map(&Map.put(&1, :has_quality, Map.get(&1, :rule_count)))
    |> Enum.map(&Map.update!(&1, :link_count, &not_zero/1))
    |> Enum.map(&Map.put(&1, :has_link, Map.get(&1, :link_count)))
    |> Enum.map(&Map.put(&1, :count, 1))
    |> Enum.group_by(
      &Enum.zip(
        get_keys(&1, @count_dimensions) ++ [:template_name],
        get_values(&1, @count_dimensions) ++ [&1.template.name]
      )
    )
    |> Enum.map(fn {key, value} ->
      %{
        dimensions:
          key
          |> Enum.filter(fn {dim, _} -> dim != :template_name end)
          |> Enum.into(%{}),
        count: value |> Enum.map(& &1.count) |> Enum.sum(),
        template_name: List.first(value).template.name |> normalize_template_name()
      }
    end)
  end

  def normalize_template_name(template_name) do
    template_name
    |> String.replace(~r/[^A-z\s]/u, "")
    |> String.replace(~r/\s+/, "_")
  end

  def get_concept_fields_completeness do
    search = %{
      query: %{bool: %{must: %{match_all: %{}}}},
      size: 10_000
    }

    content_by_name = get_content_map()

    search
    |> Search.search()
    |> Map.get(:results)
    |> atomize_concept_map()
    |> Enum.map(fn %{content: content, template: %{name: template_name}} = concept ->
      content_by_name
      |> Map.get(template_name)
      |> get_optional_fields()
      |> Enum.map(fn field ->
        case Map.get(content, field) do
          nil ->
            %{
              dimensions:
                get_map_dimensions(concept, field, Map.get(content_by_name, template_name)),
              count: 0,
              template_name: normalize_template_name(template_name)
            }

          "" ->
            %{
              dimensions:
                get_map_dimensions(concept, field, Map.get(content_by_name, template_name)),
              count: 0,
              template_name: normalize_template_name(template_name)
            }

          _ ->
            %{
              dimensions:
                get_map_dimensions(concept, field, Map.get(content_by_name, template_name)),
              count: 1,
              template_name: normalize_template_name(template_name)
            }
        end
      end)
    end)
    |> List.flatten()
  end

  defp get_map_dimensions(concept, field, content) do
    Enum.into(
      Enum.zip(
        get_keys(concept, @completeness_dimensions) ++ [:group, :field],
        get_values(concept, @completeness_dimensions) ++ get_group_and_field(field, content)
      ),
      %{}
    )
  end

  defp get_keys(concept, dimensions) do
    concept
    |> Map.take(dimensions)
    |> Map.keys()
  end

  defp get_values(concept, dimensions) do
    concept
    |> Map.take(dimensions)
    |> Map.values()
  end

  defp get_group_and_field(field, content) do
    group =
      content
      |> Enum.map(fn x ->
        if field == String.to_atom(x["name"]) do
          x["group"]
        end
      end)
      |> Enum.reject(&is_nil/1)

    case length(group) do
      0 -> ["No group"] ++ [field]
      _ -> group ++ [field]
    end
  end

  defp get_optional_fields(content) do
    content
    |> Enum.map(&CollectionUtils.atomize_keys/1)
    |> Enum.reject(&Map.get(&1, :required, false))
    |> Enum.map(&String.to_atom(&1.name))
  end

  defp atomize_concept_map(search_results) do
    search_results
    |> Enum.map(&Map.get(&1, "_source"))
    |> Enum.map(&Map.put(&1, "content", CollectionUtils.atomize_keys(Map.get(&1, "content"))))
    |> Enum.map(&Map.put(&1, "template", CollectionUtils.atomize_keys(Map.get(&1, "template"))))
    |> Enum.map(&Map.put(&1, "parent_domains", parent_domains(&1)))
    |> Enum.map(&CollectionUtils.atomize_keys/1)
  end

  def parent_domains(%{"domain_parents" => domain_parents}) do
    domain_parents
    |> Enum.map(&Map.get(&1, "name"))
    |> String.join(";")
  end

  def get_normalized_template_names do
    "bg"
    |> TemplateCache.list_by_scope!()
    |> Enum.map(&Map.get(&1, :name))
    |> Enum.map(&normalize_template_name/1)
  end
end
