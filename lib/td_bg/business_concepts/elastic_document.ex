defmodule TdBg.BusinessConcepts.ElasticDocument do
  @moduledoc """
  Elasticsearch mapping and aggregation
  definition for Business Concepts
  """

  alias Elasticsearch.Document
  alias TdBg.BusinessConcepts
  alias TdBg.BusinessConcepts.BusinessConceptVersion
  alias TdCore.Search.ElasticDocument
  alias TdCore.Search.ElasticDocumentProtocol

  defimpl Document, for: BusinessConceptVersion do
    use ElasticDocument

    alias TdBg.Taxonomies
    alias TdCache.TemplateCache
    alias TdCache.UserCache
    alias TdDfLib.Format
    alias TdDfLib.RichText

    @impl Elasticsearch.Document
    def id(%BusinessConceptVersion{id: id}), do: id

    @impl Elasticsearch.Document
    def routing(_), do: false

    @impl Elasticsearch.Document
    def encode(%BusinessConceptVersion{business_concept: business_concept} = bcv) do
      %{type: type, domain: domain, confidential: confidential, shared_to: shared_to} =
        business_concept

      template = TemplateCache.get_by_name!(type) || %{content: []}
      domain_ids = get_domain_ids(domain, shared_to)
      shared_to = get_shared_to(shared_to)
      shared_to_names = shared_to_names(shared_to)

      content =
        bcv
        |> Map.get(:content)
        |> Format.search_values(template, domain_id: domain.id)

      bcv
      |> Map.take([
        :id,
        :business_concept_id,
        :name,
        :status,
        :version,
        :last_change_at,
        :current,
        :concept_count,
        :in_progress,
        :inserted_at
      ])
      |> Map.merge(BusinessConcepts.get_concept_counts(bcv.business_concept_id))
      |> Map.put(:content, content)
      |> Map.put(:description, RichText.to_plain_text(bcv.description))
      |> Map.put(:domain, Map.take(domain, [:id, :name, :external_id]))
      |> Map.put(:domain_ids, domain_ids)
      |> Map.put(:last_change_by, get_last_change_by(bcv))
      |> Map.put(:template, Map.take(template, [:name, :label, :scope, :subscope]))
      |> Map.put(:confidential, confidential)
      |> Map.put(:shared_to_names, shared_to_names)
    end

    defp get_last_change_by(%BusinessConceptVersion{last_change_by: last_change_by}) do
      get_user(last_change_by)
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

    def mappings(_) do
      content_mappings = %{properties: get_dynamic_mappings("bg")}

      mapping_type = %{
        id: %{type: "long"},
        name: %{type: "text", fields: %{raw: %{type: "keyword", normalizer: "sortable"}}},
        description: %{type: "text"},
        version: %{type: "short"},
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
        "confidential.raw" => %{terms: %{field: "confidential.raw"}},
        "current" => %{terms: %{field: "current"}},
        "domain_ids" => %{terms: %{field: "domain_ids"}},
        "has_rules" => %{terms: %{field: "has_rules"}},
        "link_tags" => %{terms: %{field: "link_tags"}},
        "shared_to_names" => %{terms: %{field: "shared_to_names.raw"}},
        "status" => %{terms: %{field: "status"}},
        "taxonomy" => %{terms: %{field: "domain_ids", size: 500}},
        "template" => %{terms: %{field: "template.label.raw", size: 50}},
        "template_subscope" => %{terms: %{field: "template.subscope", size: 50}}
      }
      |> merge_dynamic_fields("bg", "content")
    end
  end
end
