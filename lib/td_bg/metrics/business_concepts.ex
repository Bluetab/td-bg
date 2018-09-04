defmodule TdBg.Metrics.BusinessConcepts do
  @moduledoc false

  use GenServer
  require Logger
  alias TdBg.Metrics.Instrumenter
  alias TdBg.Templates
  alias TdBg.Utils.CollectionUtils

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

  def start_link do
    GenServer.start_link(__MODULE__, %{})
  end

  def init(state) do
    if @metrics_busines_concepts_on_startup do
      Instrumenter.setup()
      schedule_work() # Schedule work to be performed at some point
    end
    {:ok, state}
  end

  def handle_info(:work, state) do
    concepts_count_metrics = get_concepts_count()
    Logger.info("Number of concepts_count metric #{inspect(length(concepts_count_metrics))}")
    Enum.each(concepts_count_metrics, &Instrumenter.set_concepts_count(&1))

    concept_fields_completness_metrics = get_concept_fields_completness()
    Logger.info("Number of concept_fields_completness metric #{inspect(length(concept_fields_completness_metrics))}")
    Enum.each(concept_fields_completness_metrics, &Instrumenter.set_concept_fields_completness(&1))

    schedule_work() # Reschedule once more
    {:noreply, state}
  end

  defp schedule_work do
    Process.send_after(self(), :work, @metrics_publication_frequency)
  end

  def get_template_map do
    Templates.list_templates
      |> Enum.map(&({&1.name, get_template_dimensions(&1)}))
      |> Map.new
  end

  defp get_template_dimensions(template) do
    template
      |> Map.get(:content)
      |> Enum.map(&get_name_dimension(&1))
      |> Enum.filter(&!is_nil(&1))
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
      |> Enum.map(&Map.update!(&1, :parent_domains, fn(current) ->
          current
          |> Enum.map(fn(domain) -> domain.name end)
          |> Enum.join(";")
        end))
      |> Enum.map(&Map.update!(&1, :q_rule_count, fn(current) ->
          case current do
            0 -> false
            _ -> true
          end
        end))
      |> Enum.map(&Map.put(&1, :has_quality, Map.get(&1, :q_rule_count)))
      |> Enum.map(&Map.update!(&1, :link_count, fn(current) ->
          case current do
            0 -> false
            _ -> true
          end
        end))
      |> Enum.map(&Map.put(&1, :has_link, Map.get(&1, :link_count)))
      |> Enum.map(&({&1, Map.get(templates_by_name, &1.type)}))
      |> Enum.filter(fn({_concept, template}) -> !is_nil(template) end)
      |> Enum.map(fn({concept, template}) -> include_template_dimensions(concept, template) end)
      |> Enum.reduce([], fn(elem, acc) -> [Map.put(elem, :count, 1) |acc] end)
      |> Enum.group_by(& Enum.zip(
          get_keys(&1, @fixed_concepts_count_dimensions, Map.get(templates_by_name, &1.type)),
          get_values(&1, @fixed_concepts_count_dimensions, Map.get(templates_by_name, &1.type)))
      )
      |> Enum.map(fn {key, value} ->
          %{dimensions: Enum.into(key, %{}),
            count: value |> Enum.map(& &1.count) |> Enum.sum(),
            template_name: List.first(value).type |> normalize_template_name()}
        end)
  end

  def normalize_template_name(template_name) do
    template_name
      |> String.replace(~r/[^A-z\s]/u, "")
      |> String.replace(~r/\s+/, "_")
  end

  defp include_empty_metrics_dimensions(concept) do
    include_template_dimensions(concept, get_concept_template_dimensions(concept.type))
  end

  defp include_template_dimensions(concept, template_dimensions) do
    Map.put(
      concept,
      :content, Map.merge(Enum.into(template_dimensions, %{}, fn(dim) -> {dim, ""} end),
      concept.content)
    )
  end

  def get_concept_fields_completness do

    search = %{
      query: %{bool: %{must: %{match_all: %{}}}},
      size: 10_000
    }

    @search_service.search("business_concept", search)
      |> Map.get(:results)
      |> atomize_concept_map()
      |> Enum.map(&Map.update!(&1, :parent_domains, fn(current) ->
          current
          |> Enum.map(fn(domain) -> domain.name end)
          |> Enum.join(";")
          end))
      |> Enum.filter(fn(concept) -> !is_nil(Templates.get_template_by_name(concept.type)) end)
      |> Enum.map(&include_empty_metrics_dimensions(&1))

      |> Enum.reduce([], fn(concept, acc) ->
          [Enum.reduce(get_not_required_fields(concept), [], fn(field, acc) ->
            case Map.get(concept.content, field) do
              nil -> [%{dimensions: get_map_dimensions(concept, field),
                        count: 0,
                        template_name: concept.type |> normalize_template_name()} |acc]
              "" -> [%{dimensions: get_map_dimensions(concept, field),
                       count: 0,
                       template_name: concept.type |> normalize_template_name()} |acc]
              _ -> [%{dimensions: get_map_dimensions(concept, field),
                      count: 1,
                      template_name: concept.type |> normalize_template_name()} |acc]
            end
          end) |acc]
        end) |> List.flatten
  end

  defp get_map_dimensions(concept, field) do
    Enum.into(Enum.zip(
      get_keys(concept, @fixed_completness_dimensions) ++ [:group, :field],
      get_values(concept, @fixed_completness_dimensions) ++ get_concept_field_and_group(concept, field)),
    %{})
  end

  defp get_keys(concept, fixed_dimensions) do
    template_dimensions = get_concept_template_dimensions(concept.type)
    get_keys(concept, fixed_dimensions, template_dimensions)
  end

  defp get_keys(concept, fixed_dimensions, template_dimensions) do
    Map.keys(Map.take(concept, fixed_dimensions)) ++
    Map.keys(Map.take(concept.content, template_dimensions))
  end

  defp get_values(concept, fixed_dimensions) do
    template_dimensions = get_concept_template_dimensions(concept.type)
    get_values(concept, fixed_dimensions, template_dimensions)
  end

  defp get_values(concept, fixed_dimensions, template_dimensions) do
    Map.values(Map.take(concept, fixed_dimensions)) ++
    Map.values(Map.take(concept.content, template_dimensions))
  end

  defp get_concept_field_and_group(concept, field) do
    group = Templates.get_template_by_name(concept.type).content
      |> Enum.map(fn (x) -> if field == String.to_atom(x["name"]) do x["group"] end end)
      |> Enum.filter(fn(elem) -> !is_nil(elem) end)

    case length(group) do
      0 -> ["No group"] ++ [field]
      _ -> group ++ [field]
    end
  end

  defp get_not_required_fields(concept) do
    Enum.reduce(Map.get(Templates.get_template_by_name(Map.get(concept, :type)), :content), [], fn(field, acc) ->
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
    |> Enum.map(&Map.put(&1, "parent_domains", Enum.map(Map.get(&1, "domain_parents"), fn(domain) -> CollectionUtils.atomize_keys(domain) end)))
    |> Enum.map(&CollectionUtils.atomize_keys(&1))
  end

  def get_dimensions_from_templates do
    Templates.list_templates()
      |> Enum.map(fn(template) -> %{name: template.name, dimensions: template.content |> Enum.map(fn(content) ->
          get_name_dimension(content) end)}
        end)
      |> Enum.map(&Map.update!(&1, :dimensions, fn(current_dimensions) ->
          Enum.filter(current_dimensions, fn(d) -> !is_nil(d) end)
        end))
  end

  def get_concept_template_dimensions(concept_type) do
    concept_type
      |> Templates.get_template_by_name()
      |> Map.get(:content)
      |> Enum.map(&get_name_dimension(&1))
      |> Enum.filter(&!is_nil(&1))
  end

  defp get_name_dimension(%{"metrics_dimension" => true} = content) do
    String.to_atom(Map.get(content, "name"))
  end
  defp get_name_dimension(_content), do: nil

end
