defmodule TdBg.BusinessConcept.Download do
  @moduledoc """
  Helper module to download business concepts.
  """

  alias Elixlsx.{Sheet, Workbook}
  alias TdBg.BusinessConcept.Upload
  alias TdCache.DomainCache
  alias TdCache.I18nCache
  alias TdCache.TemplateCache
  alias TdDfLib.I18n
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

  @headers_translatable ["name"]

  @url_schema_headers [
    "link_to_concept"
  ]

  def to_xlsx(concepts, lang, opts \\ []) do
    concept_url_schema = Keyword.get(opts, :concept_url_schema, nil)
    translations = Keyword.get(opts, :translations, false)

    {:ok, templates} = TemplateCache.list_by_scope("bg")

    templates_map =
      Enum.into(templates, %{}, fn template -> {template.name, template} end)

    locales = I18nCache.get_active_locales!()

    default_locale =
      case I18nCache.get_default_locale() do
        {:ok, locale} -> locale
        _ -> "en"
      end

    domains_name = DomainCache.id_to_name_map()
    domains_external_id = DomainCache.id_to_external_id_map()

    concepts
    |> Enum.group_by(&(&1 |> Map.get("template") |> Map.get("name")))
    |> Enum.map(fn {template_name, template_concepts} ->
      [template_fields, translatable_fields] =
        case Map.get(templates_map, template_name) do
          nil ->
            [[], []]

          template ->
            fields =
              template
              |> type_fields()
              |> Enum.uniq_by(&Map.get(&1, "name"))

            translatable_fields = I18n.get_translatable_fields(template)

            [fields, translatable_fields]
        end

      xlsx_headers =
        template_fields
        |> Enum.map(fn field ->
          field_name = Map.get(field, "name")
          get_field_name(locales, field_name, translatable_fields, translations)
        end)
        |> List.flatten()

      all_headers =
        xlsx_headers
        |> get_all_headers(concept_url_schema, translations: translations, locales: locales)
        |> highlight_headers(xlsx_headers, translations: translations, locales: locales)

      parser_opts = [
        domain_type: :with_domain_external_id,
        lang: lang,
        xlsx: true,
        translations: translations,
        locales: locales,
        default_locale: default_locale
      ]

      parsing_context =
        template_fields
        |> Parser.context_for_fields(:with_domain_external_id, domains_name, domains_external_id)
        |> Map.put("lang", lang)

      core =
        Enum.map(template_concepts, fn %{"content" => content} = concept ->
          @headers
          |> Enum.map(
            &editable_concept_value(concept, &1,
              lang: lang,
              locales: locales,
              default_locale: default_locale,
              translations: translations
            )
          )
          |> List.flatten()
          |> add_extra_fields(concept, concept_url_schema)
          |> Parser.append_parsed_fields(template_fields, content, parser_opts, parsing_context)
        end)

      template_name =
        if template_name !== nil, do: sanitize_sheet_name(template_name), else: "null"

      %Sheet{
        name: template_name,
        rows: [all_headers | core]
      }
    end)
    |> then(&%Workbook{sheets: &1})
  end

  def to_csv(concepts, lang, concept_url_schema \\ nil) do
    locales = I18nCache.get_active_locales!()

    default_locale =
      case I18nCache.get_default_locale() do
        {:ok, locale} -> locale
        _ -> "en"
      end

    {:ok, templates} = TemplateCache.list_by_scope("bg")

    templates_map =
      Enum.into(templates, %{}, fn template -> {template.name, template} end)

    domains_name = DomainCache.id_to_name_map()
    domains_external_id = DomainCache.id_to_external_id_map()

    type_fields =
      concepts
      |> Enum.group_by(&(&1 |> Map.get("template") |> Map.get("name")))
      |> Map.keys()
      |> Enum.flat_map(fn type ->
        templates_map
        |> Map.get(type)
        |> type_fields()
        |> Enum.uniq_by(&Map.get(&1, "name"))
      end)

    type_headers = Enum.map(type_fields, &Map.get(&1, "name"))

    all_headers = get_all_headers(type_headers, concept_url_schema)

    parsing_context =
      type_fields
      |> Parser.context_for_fields(:with_domain_external_id, domains_name, domains_external_id)
      |> Map.put("lang", lang)

    parser_opts = [
      domain_type: :with_domain_external_id,
      lang: lang,
      locales: locales,
      default_locale: default_locale
    ]

    core =
      Enum.map(concepts, fn %{"content" => content} = concept ->
        @headers
        |> Enum.map(
          &editable_concept_value(concept, &1,
            lang: lang,
            translations: false,
            locales: locales,
            default_locale: default_locale
          )
        )
        |> add_extra_fields(concept, concept_url_schema)
        |> Parser.append_parsed_fields(type_fields, content, parser_opts, parsing_context)
      end)

    [all_headers | core]
    |> CSV.encode(separator: ?;)
    |> Enum.to_list()
    |> to_string()
  end

  defp type_fields(%{content: content}) when is_list(content),
    do: Enum.flat_map(content, &Map.get(&1, "fields"))

  defp type_fields(_type), do: []

  defp editable_concept_value(concept, header, opts)

  defp editable_concept_value(%{"template" => template}, "template", _),
    do: Map.get(template, "name")

  defp editable_concept_value(%{"domain" => domain}, "domain_external_id", _),
    do: Map.get(domain, "external_id")

  defp editable_concept_value(%{"domain" => domain}, "domain_name", _),
    do: Map.get(domain, "name")

  defp editable_concept_value(concept, "completeness", _), do: get_completeness(concept)

  defp editable_concept_value(%{"business_concept_id" => id}, "id", _), do: id

  defp editable_concept_value(%{"id" => id}, "current_version_id", _), do: id

  defp editable_concept_value(%{"status" => status}, "status", opts) do
    lang = Keyword.get(opts, :lang)
    I18nCache.get_definition(lang, "concepts.status.#{status}", default_value: status)
  end

  defp editable_concept_value(concept, field, opts) when field in @headers_translatable do
    default_locale = Keyword.get(opts, :default_locale)
    translations = Keyword.get(opts, :translations, false)

    if translations do
      opts
      |> Keyword.get(:locales)
      |> Enum.map(fn
        locale when locale != default_locale ->
          Map.get(concept, "#{field}_#{locale}")

        _ ->
          Map.get(concept, field)
      end)
    else
      lang = Keyword.get(opts, :lang)

      if lang == default_locale do
        Map.get(concept, field)
      else
        Map.get(concept, "#{field}_#{lang}")
      end
    end
  end

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

  defp get_all_headers(type_headers, nil, translations: false, locales: _),
    do: @headers ++ type_headers

  defp get_all_headers(type_headers, _concepts_url_schema, translations: false, locales: _),
    do: @headers ++ @url_schema_headers ++ type_headers

  defp get_all_headers(type_headers, nil, translations: true, locales: locales),
    do: expand_translatable_header(@headers, locales) ++ type_headers

  defp get_all_headers(type_headers, _concepts_url_schema, translations: true, locales: locales),
    do: expand_translatable_header(@headers, locales) ++ @url_schema_headers ++ type_headers

  defp expand_translatable_header(headers, locales) do
    headers
    |> Enum.map(fn
      header when header in @headers_translatable ->
        Enum.map(locales, &"#{header}_#{&1}")

      header ->
        header
    end)
    |> List.flatten()
  end

  defp add_extra_fields(editable_fields, _, nil), do: editable_fields

  defp add_extra_fields(editable_fields, concept, concept_url_schema),
    do: editable_fields ++ [get_concept_url_schema(concept_url_schema, concept)]

  defp highlight_headers(headers, template_headers, opts) do
    %{required: requireds, update_required: update_requireds} = Upload.get_headers(opts)

    Enum.map(headers, fn
      h ->
        cond do
          h in requireds -> [h, bg_color: "#ffd428"]
          h in update_requireds -> [h, bg_color: "#ffe994"]
          h in template_headers -> [h, bg_color: "#ffe994"]
          true -> h
        end
    end)
  end

  defp get_field_name(locales, field_name, translatable_fields, translations) do
    if field_name in translatable_fields and translations do
      Enum.map(locales, &"#{field_name}_#{&1}")
    else
      field_name
    end
  end

  defp sanitize_sheet_name(name) when is_binary(name) do
    name
    # Reemplazar caracteres no permitidos
    |> String.replace(~r/[[\]:*?\/\\]/, "_")
    # Limitar a 31 caracteres
    |> String.slice(0, 31)
    |> then(fn
      # Si queda vacío, usar un nombre por defecto
      "" -> "Sheet"
      name -> name
    end)
  end

  defp sanitize_sheet_name(_), do: "Sheet"
end
