defmodule TdBg.BusinessConcepts.ElasticDocument do
  @moduledoc """
  Elasticsearch mapping and aggregation
  definition for Business Concepts
  """

  alias Elasticsearch.Document
  alias TdBg.BusinessConcepts
  alias TdBg.BusinessConcepts.BusinessConceptVersion
  alias TdCore.Search.Cluster
  alias TdCore.Search.ElasticDocument
  alias TdCore.Search.ElasticDocumentProtocol

  defimpl Document, for: BusinessConceptVersion do
    use ElasticDocument

    alias TdBg.I18nContents.I18nContents
    alias TdBg.Taxonomies
    alias TdCache.I18nCache
    alias TdCache.TemplateCache
    alias TdCache.UserCache
    alias TdDfLib.Format

    @impl Elasticsearch.Document
    def id(%BusinessConceptVersion{id: id}), do: id

    @impl Elasticsearch.Document
    def routing(_), do: false

    @impl Elasticsearch.Document
    def encode(%BusinessConceptVersion{id: bcv_id, business_concept: business_concept} = bcv) do
      %{
        type: type,
        domain: domain,
        confidential: confidential,
        shared_to: shared_to
      } = business_concept

      template = TemplateCache.get_by_name!(type) || %{content: []}
      domain_ids = get_domain_ids(domain, shared_to)
      shared_to = get_shared_to(shared_to)
      shared_to_names = shared_to_names(shared_to)

      content =
        bcv
        |> Map.get(:content)
        |> Format.search_values(template, domain_id: domain.id)
        |> put_i18n_content(bcv_id, template)
        |> Enum.into(%{}, fn {field, %{"value" => value}} -> {field, value} end)

      {last_change_at, last_change_by} = BusinessConceptVersion.get_last_change(bcv)

      bcv
      |> Map.take([
        :id,
        :name,
        :business_concept_id,
        :status,
        :version,
        :current,
        :concept_count,
        :in_progress,
        :inserted_at
      ])
      |> Map.merge(BusinessConcepts.get_concept_counts(bcv.business_concept_id))
      |> put_i18n_concept_property(:name, bcv)
      |> Map.put(:content, content)
      |> Map.put(:domain, Map.take(domain, [:id, :name, :external_id]))
      |> Map.put(:domain_ids, domain_ids)
      |> Map.put(:last_change_by, get_user(last_change_by))
      |> Map.put(:last_change_at, last_change_at)
      |> Map.put(:template, Map.take(template, [:name, :label, :scope, :subscope]))
      |> Map.put(:confidential, confidential)
      |> Map.put(:shared_to_names, shared_to_names)
    end

    defp put_i18n_concept_property(bcv_to_index, property, %{id: id}) do
      {:ok, default_locale} = I18nCache.get_default_locale()

      case I18nContents.get_all_i18n_content_by_bcv_id(id) do
        [_ | _] = i18n ->
          i18n
          |> Enum.map(&map_property_locale(&1, property, default_locale))
          |> Enum.reject(fn {_, v} -> v == nil end)
          |> Map.new()
          |> Map.merge(bcv_to_index)

        _ ->
          bcv_to_index
      end
    end

    defp map_property_locale(%{lang: locale} = i18n, property, default_locale) do
      locale_property =
        if locale == default_locale,
          do: property,
          else: String.to_atom("#{property}_#{locale}")

      i18n_value = Map.get(i18n, property)

      {locale_property, i18n_value}
    end

    defp put_i18n_content(content, bcv_id, template) do
      case I18nContents.get_all_i18n_content_by_bcv_id(bcv_id) do
        [_ | _] = i18n ->
          i18n
          |> map_content_locale(template)
          |> Map.merge(content)

        _ ->
          content
      end
    end

    defp map_content_locale(i18n, template) do
      i18n
      |> Enum.map(fn %{lang: locale, content: i18n_content} ->
        i18n_content
        |> Format.search_values(template, apply_default_values?: false)
        |> add_lang_suffix(locale)
      end)
      |> Enum.reduce(%{}, fn map, acc -> Map.merge(acc, map) end)
    end

    defp add_lang_suffix(formatted_content, locale) do
      Enum.into(formatted_content, %{}, fn {key, value} ->
        {"#{key}_#{locale}", value}
      end)
    end

    defp get_user(user_id) do
      case UserCache.get(user_id) do
        {:ok, nil} -> %{}
        {:ok, user} -> user
      end
    end

    defp get_shared_to(shared_to) do
      shared_to
      |> Enum.map(&Taxonomies.get_parents(&1.id))
      |> List.flatten()
      |> Enum.filter(& &1)
      |> Enum.uniq_by(& &1.id)
    end

    defp get_domain_ids(domain, shared_to) do
      Enum.map([domain | List.wrap(shared_to)], & &1.id)
    end

    defp shared_to_names([]), do: nil

    defp shared_to_names(shared_to), do: Enum.map(shared_to, & &1.name)
  end

  defimpl ElasticDocumentProtocol, for: BusinessConceptVersion do
    use ElasticDocument

    @translatable_fields [:name]

    def mappings(_) do
      content_mappings = %{properties: get_dynamic_mappings("bg")}

      mapping_type =
        %{
          id: %{type: "long"},
          name: %{type: "text", fields: %{raw: %{type: "keyword", normalizer: "sortable"}}},
          description: %{type: "text"},
          version: %{type: "long"},
          template: %{
            properties: %{
              name: %{type: "text"},
              label: %{type: "text", fields: @raw},
              subscope: %{type: "keyword", null_value: ""}
            }
          },
          status: %{type: "keyword"},
          last_change_at: %{type: "date", format: "strict_date_optional_time||epoch_millis"},
          inserted_at: %{type: "date", format: "strict_date_optional_time||epoch_millis"},
          current: %{type: "boolean"},
          confidential: %{type: "boolean", fields: @raw},
          in_progress: %{type: "boolean"},
          domain: %{
            properties: %{
              id: %{type: "long"},
              name: %{type: "text", fields: @raw_sort},
              external_id: %{type: "text", fields: @raw}
            }
          },
          last_change_by: %{
            properties: %{
              id: %{type: "long"},
              user_name: %{type: "text", fields: @raw},
              full_name: %{type: "text", fields: @raw}
            }
          },
          domain_ids: %{type: "long"},
          shared_to_names: %{type: "text", fields: %{raw: %{type: "keyword", null_value: ""}}},
          link_tags: %{type: "keyword"},
          has_rules: %{type: "boolean"},
          content: content_mappings
        }
        |> add_locales_fields_mapping(@translatable_fields)

      settings = %{
        number_of_shards: 1,
        analysis: %{
          normalizer: %{
            sortable: %{type: "custom", char_filter: [], filter: ["lowercase", "asciifolding"]}
          }
        }
      }

      %{mappings: %{properties: mapping_type}, settings: settings}
    end

    def aggregations(_) do
      %{
        "confidential.raw" => %{
          terms: %{field: "confidential.raw", size: Cluster.get_size_field("confidential.raw")}
        },
        "current" => %{terms: %{field: "current", size: Cluster.get_size_field("current")}},
        "domain_ids" => %{
          terms: %{field: "domain_ids", size: Cluster.get_size_field("domain_ids")}
        },
        "has_rules" => %{terms: %{field: "has_rules", size: Cluster.get_size_field("has_rules")}},
        "link_tags" => %{terms: %{field: "link_tags", size: Cluster.get_size_field("link_tags")}},
        "shared_to_names" => %{
          terms: %{field: "shared_to_names.raw", size: Cluster.get_size_field("shared_to_names")}
        },
        "status" => %{terms: %{field: "status", size: Cluster.get_size_field("status")}},
        "taxonomy" => %{terms: %{field: "domain_ids", size: Cluster.get_size_field("taxonomy")}},
        "template" => %{
          terms: %{field: "template.label.raw", size: Cluster.get_size_field("template")}
        },
        "template_subscope" => %{
          terms: %{field: "template.subscope", size: Cluster.get_size_field("template_subscope")}
        }
      }
      |> merge_dynamic_fields("bg", "content")
    end
  end
end
