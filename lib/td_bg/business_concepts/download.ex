defmodule TdBg.BusinessConcept.Download do
  @moduledoc """
  Helper module to download business concepts.
  """

  alias Elixlsx.{Sheet, Workbook}
  alias TdBg.BusinessConcept.Upload
  alias TdCache.I18nCache
  alias TdCache.TemplateCache
  alias TdDfLib.Parser
  alias TdDfLib.Templates

  @headers [
    "id",
    "current_version_id",
    "name",
    "domain_external_id",
    "domain_name",
    "status",
    "completeness",
    "last_change_at",
    "inserted_at"
  ]

  @url_schema_headers [
    "link_to_concept"
  ]

  def to_xlsx(concepts, lang, concept_url_schema \\ nil) do
    concepts
    |> Enum.group_by(&(&1 |> Map.get("template") |> Map.get("name")))
    |> Enum.map(fn {template_name, template_concepts} ->
      template_fields =
        case TemplateCache.get_by_name!(template_name) do
          nil ->
            []

          template ->
            template
            |> type_fields()
            |> Enum.uniq_by(&Map.get(&1, "name"))
        end

      xlsx_headers = Enum.map(template_fields, &Map.get(&1, "name"))

      all_headers =
        xlsx_headers
        |> get_all_headers(concept_url_schema)
        |> highlight_headers()

      core =
        Enum.map(template_concepts, fn %{"content" => content} = concept ->
          @headers
          |> Enum.map(&editable_concept_value(concept, &1, lang))
          |> add_extra_fields(concept, concept_url_schema)
          |> Parser.append_parsed_fields(template_fields, content,
            domain_type: :with_domain_external_id,
            lang: lang,
            xlsx: true
          )
        end)

      template_name = if template_name !== nil, do: template_name, else: "null"

      %Sheet{
        name: template_name,
        rows: [all_headers | core]
      }
    end)
    |> then(&%Workbook{sheets: &1})
  end

  def to_csv(concepts, lang, concept_url_schema \\ nil) do
    type_fields =
      concepts
      |> Enum.group_by(&(&1 |> Map.get("template") |> Map.get("name")))
      |> Map.keys()
      |> Enum.flat_map(fn type ->
        TemplateCache.get_by_name!(type)
        |> type_fields()
        |> Enum.uniq_by(&Map.get(&1, "name"))
      end)

    type_headers = Enum.map(type_fields, &Map.get(&1, "name"))

    all_headers = get_all_headers(type_headers, concept_url_schema)

    core =
      Enum.map(concepts, fn %{"content" => content} = concept ->
        @headers
        |> Enum.map(&editable_concept_value(concept, &1, lang))
        |> add_extra_fields(concept, concept_url_schema)
        |> Parser.append_parsed_fields(type_fields, content,
          domain_type: :with_domain_external_id,
          lang: lang
        )
      end)

    [all_headers | core]
    |> CSV.encode(separator: ?;)
    |> Enum.to_list()
    |> to_string()
  end

  defp type_fields(%{content: content}) when is_list(content),
    do: Enum.flat_map(content, &Map.get(&1, "fields"))

  defp type_fields(_type), do: []

  defp editable_concept_value(concept, header, lang)

  defp editable_concept_value(%{"template" => template}, "template", _),
    do: Map.get(template, "name")

  defp editable_concept_value(%{"domain" => domain}, "domain_external_id", _),
    do: Map.get(domain, "external_id")

  defp editable_concept_value(%{"domain" => domain}, "domain_name", _),
    do: Map.get(domain, "name")

  defp editable_concept_value(concept, "completeness", _), do: get_completeness(concept)

  defp editable_concept_value(%{"business_concept_id" => id}, "id", _), do: id

  defp editable_concept_value(%{"id" => id}, "current_version_id", _), do: id

  defp editable_concept_value(%{"status" => status}, "status", lang),
    do: I18nCache.get_definition(lang, "concepts.status.#{status}", default_value: status)

  defp editable_concept_value(concept, field, _), do: Map.get(concept, field)

  defp get_completeness(%{"content" => content, "template" => %{"name" => template_name}}),
    do: Templates.completeness(content, template_name)

  defp get_completeness(_), do: 0.0

  defp get_concept_url_schema(url_schema, concept) do
    if String.contains?(url_schema, ":business_concept_id") and
         String.contains?(url_schema, "/:id") do
      url_schema
      |> String.replace(":business_concept_id", to_string(concept["business_concept_id"]))
      |> String.replace(":id", to_string(concept["id"]))
    else
      nil
    end
  end

  defp get_all_headers(type_headers, nil), do: @headers ++ type_headers

  defp get_all_headers(type_headers, _concepts_url_schema),
    do: @headers ++ @url_schema_headers ++ type_headers

  defp add_extra_fields(editable_fields, _, nil), do: editable_fields

  defp add_extra_fields(editable_fields, concept, concept_url_schema),
    do: editable_fields ++ [get_concept_url_schema(concept_url_schema, concept)]

  defp highlight_headers(headers) do
    %{required: requireds, update_required: update_requireds} = Upload.get_headers()

    headers
    |> Enum.map(fn
      h ->
        cond do
          h in requireds -> [h, bg_color: "#ffd428"]
          h in update_requireds -> [h, bg_color: "#ffe994"]
          true -> h
        end
    end)
  end
end
