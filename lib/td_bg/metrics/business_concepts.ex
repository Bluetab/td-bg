defmodule TdBg.Metrics.BusinessConcepts do
  @moduledoc false

  use GenServer
  require Logger
  alias TdBg.Metrics.Instrumenter
  alias TdBg.Utils.CollectionUtils
  @df_cache Application.get_env(:td_bg, :df_cache)

  @search_service Application.get_env(:td_bg, :elasticsearch)[:search_service]

  @fixed_concepts_count_dimensions [:status, :parent_domains, :has_quality, :has_link]
  @fixed_completness_dimensions [:id, :group, :field, :status, :parent_domains]

  @metrics_busines_concepts_on_startup Application.get_env(
                                         :td_bg,
                                         :metrics_busines_concepts_on_startup
                                       )

  @metrics_publication_frequency Application.get_env(
                                   :td_bg,
                                   :metrics_publication_frequency
                                 )

  def start_link(opts \\ %{}) do
    GenServer.start_link(__MODULE__, opts)
  end

  def init(state) do
    if @metrics_busines_concepts_on_startup do
      # Schedule work to be performed at some point
      schedule_work()
    end

    {:ok, state}
  end

  def handle_info(:work, state) do
    Instrumenter.setup()
    concepts_count_metrics = get_concepts_count()
    Logger.info("Number of concepts_count metric #{inspect(length(concepts_count_metrics))}")
    Enum.each(concepts_count_metrics, &Instrumenter.set_concepts_count(&1))

    concept_fields_completness_metrics = get_concept_fields_completness()

    Logger.info(
      "Number of concept_fields_completness metric #{
        inspect(length(concept_fields_completness_metrics))
      }"
    )

    Enum.each(
      concept_fields_completness_metrics,
      &Instrumenter.set_concept_fields_completness(&1)
    )

    # Reschedule once more
    schedule_work()
    {:noreply, state}
  end

  defp schedule_work do
    Process.send_after(self(), :work, @metrics_publication_frequency)
  end

  def get_template_map do
    @df_cache.list_templates()
    |> Enum.map(&{&1.name, get_template_dimensions(&1)})
    |> Map.new()
  end

  def get_content_map do
    @df_cache.list_templates()
    |> Enum.map(&{&1.name, &1.content})
    |> Map.new()
  end

  defp get_template_dimensions(template) do
    template
    |> Map.get(:content)
    |> Enum.map(&get_name_dimension(&1))
    |> Enum.filter(&(!is_nil(&1)))
  end

  def get_concepts_count do
    search = %{
      query: %{bool: %{must: %{match_all: %{}}}},
      size: 10_000
    }

    templates_by_name = get_template_map()

    @search_service.search("business_concept", search)
    |> Map.get(:results)
    |> atomize_concept_map()
    |> Enum.map(
      &Map.update!(&1, :parent_domains, fn current ->
        current
        |> Enum.map(fn domain -> domain.name end)
        |> Enum.join(";")
      end)
    )
    |> Enum.map(
      &Map.update!(&1, :rule_count, fn current ->
        case current do
          0 -> false
          _ -> true
        end
      end)
    )
    |> Enum.map(&Map.put(&1, :has_quality, Map.get(&1, :rule_count)))
    |> Enum.map(
      &Map.update!(&1, :link_count, fn current ->
        case current do
          0 -> false
          _ -> true
        end
      end)
    )
    |> Enum.map(&Map.put(&1, :has_link, Map.get(&1, :link_count)))
    |> Enum.map(&{&1, Map.get(templates_by_name, &1.template.name)})
    |> Enum.filter(fn {_concept, template} -> !is_nil(template) end)
    |> Enum.map(fn {concept, template} -> include_template_dimensions(concept, template) end)
    |> Enum.reduce([], fn elem, acc -> [Map.put(elem, :count, 1) | acc] end)
    |> Enum.group_by(
      &Enum.zip(
        get_keys(&1, @fixed_concepts_count_dimensions, Map.get(templates_by_name, &1.template.name)) ++ [:template_name],
        get_values(&1, @fixed_concepts_count_dimensions, Map.get(templates_by_name, &1.template.name)) ++ [&1.template.name]
      )
    )
    |> Enum.map(fn {key, value} ->
      %{
        dimensions: key 
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

  defp include_template_dimensions(concept, template_dimensions) do
    Map.put(
      concept,
      :content,
      Map.merge(
        Enum.into(template_dimensions, %{}, fn dim -> {dim, ""} end),
        concept.content
      )
    )
  end

  def get_concept_fields_completness do
    search = %{
      query: %{bool: %{must: %{match_all: %{}}}},
      size: 10_000
    }

    templates_by_name = get_template_map()
    content_by_name = get_content_map()

    @search_service.search("business_concept", search)
    |> Map.get(:results)
    |> atomize_concept_map()
    |> Enum.map(
      &Map.update!(&1, :parent_domains, fn current ->
        current
        |> Enum.map(fn domain -> domain.name end)
        |> Enum.join(";")
      end)
    )
    |> Enum.map(&{&1, Map.get(templates_by_name, &1.template.name)})
    |> Enum.filter(fn {_concept, template} -> !is_nil(template) end)
    |> Enum.map(fn {concept, template} -> include_template_dimensions(concept, template) end)
    |> Enum.reduce([], fn concept, acc ->
      [
        Enum.reduce(
          get_not_required_fields(Map.get(content_by_name, concept.template.name)),
          [],
          fn field, acc ->
            case Map.get(concept.content, field) do
              nil ->
                [
                  %{
                    dimensions:
                      get_map_dimensions(
                        concept,
                        field,
                        Map.get(templates_by_name, concept.template.name),
                        Map.get(content_by_name, concept.template.name)
                      ),
                    count: 0,
                    template_name: concept.template.name |> normalize_template_name()
                  }
                  | acc
                ]

              "" ->
                [
                  %{
                    dimensions:
                      get_map_dimensions(
                        concept,
                        field,
                        Map.get(templates_by_name, concept.template.name),
                        Map.get(content_by_name, concept.template.name)
                      ),
                    count: 0,
                    template_name: concept.template.name |> normalize_template_name()
                  }
                  | acc
                ]

              _ ->
                [
                  %{
                    dimensions:
                      get_map_dimensions(
                        concept,
                        field,
                        Map.get(templates_by_name, concept.template.name),
                        Map.get(content_by_name, concept.template.name)
                      ),
                    count: 1,
                    template_name: concept.template.name |> normalize_template_name()
                  }
                  | acc
                ]
            end
          end
        )
        | acc
      ]
    end)
    |> List.flatten()
  end

  defp get_map_dimensions(concept, field, template_dimensions, content) do
    Enum.into(
      Enum.zip(
        get_keys(concept, @fixed_completness_dimensions, template_dimensions) ++ [:group, :field],
        get_values(concept, @fixed_completness_dimensions, template_dimensions) ++
          get_field_and_group(field, content)
      ),
      %{}
    )
  end

  defp get_keys(concept, fixed_dimensions, template_dimensions) do
    Map.keys(Map.take(concept, fixed_dimensions)) ++
      Map.keys(Map.take(concept.content, template_dimensions))
  end

  defp get_values(concept, fixed_dimensions, template_dimensions) do
    Map.values(Map.take(concept, fixed_dimensions)) ++
      Map.values(Map.take(concept.content, template_dimensions))
  end

  defp get_field_and_group(field, content) do
    group =
      content
      |> Enum.map(fn x ->
        if field == String.to_atom(x["name"]) do
          x["group"]
        end
      end)
      |> Enum.filter(fn elem -> !is_nil(elem) end)

    case length(group) do
      0 -> ["No group"] ++ [field]
      _ -> group ++ [field]
    end
  end

  defp get_not_required_fields(content) do
    Enum.reduce(content, [], fn field, acc ->
      if Map.get(CollectionUtils.atomize_keys(field), :required, false) do
        acc ++ []
      else
        acc ++ [String.to_atom(CollectionUtils.atomize_keys(field).name)]
      end
    end)
  end

  defp atomize_concept_map(business_concept_version) do
    business_concept_version
    |> Enum.map(&Map.get(&1, "_source"))
    |> Enum.map(&Map.put(&1, "content", CollectionUtils.atomize_keys(Map.get(&1, "content"))))
    |> Enum.map(&Map.put(&1, "template", CollectionUtils.atomize_keys(Map.get(&1, "template"))))
    |> Enum.map(
      &Map.put(
        &1,
        "parent_domains",
        Enum.map(Map.get(&1, "domain_parents"), fn domain ->
          CollectionUtils.atomize_keys(domain)
        end)
      )
    )
    |> Enum.map(&CollectionUtils.atomize_keys(&1))
  end

  def get_dimensions_from_templates do
    @df_cache.list_templates()
    |> Enum.map(fn template ->
      %{
        name: template.name,
        dimensions:
          template.content
          |> Enum.map(fn content ->
            get_name_dimension(content)
          end)
      }
    end)
    |> Enum.map(
      &Map.update!(&1, :dimensions, fn current_dimensions ->
        Enum.filter(current_dimensions, fn d -> !is_nil(d) end)
      end)
    )
  end

  def get_concept_template_dimensions(concept_type) do
    concept_type
    |> @df_cache.get_template_by_name()
    |> Map.get(:content)
    |> Enum.map(&get_name_dimension(&1))
    |> Enum.filter(&(!is_nil(&1)))
  end

  defp get_name_dimension(%{"metrics_dimension" => true} = content) do
    String.to_atom(Map.get(content, "name"))
  end

  defp get_name_dimension(_content), do: nil
end
