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
    alias TdDfLib.Content
    alias TdDfLib.Format
    alias TdDfLib.I18n

    @impl Elasticsearch.Document
    def id(%BusinessConceptVersion{id: id}), do: id

    @impl Elasticsearch.Document
    def routing(_), do: false

    def encode(%BusinessConceptVersion{embeddings: %{} = embeddings})
        when map_size(embeddings) > 0 do
      %{doc: %{embeddings: embeddings}}
    end

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

      {:ok, default_locale} = I18nCache.get_default_locale()
      active_locales = I18nCache.get_active_locales!() -- [default_locale]

      i18n_contents =
        bcv_id
        |> I18nContents.get_all_i18n_content_by_bcv_id()
        |> Enum.into(%{}, &{&1.lang, &1})
        |> default_for_active_langs(active_locales)

      content =
        bcv
        |> Map.get(:content)
        |> Format.search_values(template, domain_id: domain.id)
        |> put_i18n_content(i18n_contents, template)
        |> Content.to_legacy()

      {last_change_at, last_change_by} = BusinessConcepts.get_last_change(bcv)

      {bcv_last_change_at, bcv_last_change_by} = BusinessConcepts.get_last_change_version(bcv)

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
        :inserted_at,
        :updated_at
      ])
      |> Map.put(:ngram_name, bcv.name)
      |> Map.merge(BusinessConcepts.get_concept_counts(bcv.business_concept_id))
      |> put_i18n_concept_property(:name, i18n_contents, default_locale)
      |> put_i18n_concept_property(:ngram_name, i18n_contents, default_locale)
      |> Map.put(:content, content)
      |> Map.put(:domain, Map.take(domain, [:id, :name, :external_id]))
      |> Map.put(:domain_ids, domain_ids)
      |> Map.put(:bcv_last_change_by, get_user(bcv_last_change_by))
      |> Map.put(:bcv_last_change_at, bcv_last_change_at)
      |> Map.put(:last_change_at, last_change_at)
      |> Map.put(:last_change_by, get_user(last_change_by))
      |> Map.put(:template, Map.take(template, [:name, :label, :scope, :subscope]))
      |> Map.put(:confidential, confidential)
      |> Map.put(:shared_to_names, shared_to_names)
      |> add_embeddings(bcv)
    end

    defp put_i18n_concept_property(bcv_to_index, property, i18n, default_locale) do
      original_value = Map.get(bcv_to_index, property)

      i18n
      |> Enum.map(&map_property_locale(&1, property, original_value, default_locale))
      |> Enum.reject(fn {_, v} -> v == nil end)
      |> Map.new()
      |> Map.merge(bcv_to_index)
    end

    defp map_property_locale(
           {locale, i18n},
           :ngram_name = property,
           original_value,
           default_locale
         ) do
      locale_property = property_with_locale(property, locale, default_locale)
      i18n_value = Map.get(i18n, :name) || original_value
      {locale_property, i18n_value}
    end

    defp map_property_locale({locale, i18n}, property, original_value, default_locale) do
      locale_property = property_with_locale(property, locale, default_locale)
      i18n_value = Map.get(i18n, property) || original_value
      {locale_property, i18n_value}
    end

    defp property_with_locale(property, locale, default_locale) when locale == default_locale,
      do: property

    defp property_with_locale(property, locale, _default_locale) do
      String.to_atom("#{property}_#{locale}")
    end

    defp put_i18n_content(content, i18n, template) do
      i18n
      |> Enum.map(&format_content_locale(&1, template, content))
      |> Enum.reduce(%{}, fn map, acc -> Map.merge(acc, map) end)
      |> Map.merge(content)
    end

    defp format_content_locale({locale, %{content: i18n_content}}, template, content) do
      translatable_fields = I18n.get_translatable_fields(template)

      i18n_content
      |> Format.search_values(template, apply_default_values?: false)
      |> translatable_defaults(translatable_fields, content)
      |> add_lang_suffix(locale)
    end

    defp add_lang_suffix(formatted_content, locale) do
      Enum.into(formatted_content, %{}, fn {key, value} ->
        {"#{key}_#{locale}", value}
      end)
    end

    defp translatable_defaults(i18n_content, translatable_fields, content) do
      Enum.reduce(translatable_fields, i18n_content, fn field, acc ->
        original_value = Map.get(content, field)

        get_translatable_field(acc, field, original_value)
      end)
    end

    defp get_translatable_field(acc, _field, nil), do: acc

    defp get_translatable_field(acc, field, original_value) do
      case Map.get(acc, field) do
        %{"value" => value} when value in [nil, ""] -> Map.put(acc, field, original_value)
        nil -> Map.put(acc, field, original_value)
        _ -> acc
      end
    end

    defp default_for_active_langs(i18n_content, active_locales) do
      active_locales
      |> Enum.into(%{}, fn locale -> {locale, %{content: %{}}} end)
      |> Map.merge(i18n_content)
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

    defp add_embeddings(content, %{record_embeddings: [_ | _]} = bcv) do
      embeddings = BusinessConceptVersion.vector_embeddings(bcv)
      Map.put(content, :embeddings, embeddings)
    end

    defp add_embeddings(content, _business_concept_version), do: content
  end

  defimpl ElasticDocumentProtocol, for: BusinessConceptVersion do
    use ElasticDocument

    @translatable_fields [:name, :ngram_name]
    @search_fields ~w(ngram_name*^3)
    @simple_search_fields ~w(name)

    def mappings(_) do
      content_mappings = %{properties: get_dynamic_mappings("bg", add_locales?: true)}

      mapping_type =
        %{
          id: %{type: "long"},
          name: %{
            type: "text",
            fields: %{
              raw: %{type: "keyword", normalizer: "sortable"},
              exact: %{type: "text", analyzer: "exact_analyzer"}
            }
          },
          ngram_name: %{type: "search_as_you_type"},
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
          bcv_last_change_at: %{type: "date", format: "strict_date_optional_time||epoch_millis"},
          inserted_at: %{type: "date", format: "strict_date_optional_time||epoch_millis"},
          updated_at: %{type: "date", format: "strict_date_optional_time||epoch_millis"},
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
          content: content_mappings,
          embeddings: %{properties: get_embedding_mappings()}
        }
        |> add_locales_fields_mapping(@translatable_fields)

      settings =
        :concepts
        |> Cluster.setting()
        |> apply_lang_settings()

      %{mappings: %{properties: mapping_type}, settings: settings}
    end

    def aggregations(_) do
      merged_aggregations("bg")
    end

    def query_data(_) do
      content_schema = Templates.content_schema_for_scope("bg")
      dynamic_fields = content_schema |> dynamic_search_fields("content") |> add_locales()
      simple_search_fields = add_locales(@simple_search_fields) ++ dynamic_fields

      %{
        fields: @search_fields ++ dynamic_fields,
        simple_search_fields: simple_search_fields,
        aggs: merged_aggregations(content_schema)
      }
    end

    defp native_aggregations do
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
    end

    defp merged_aggregations(scope_or_schema) do
      native_aggregations = native_aggregations()
      merge_dynamic_aggregations(native_aggregations, scope_or_schema, "content")
    end
  end
end
