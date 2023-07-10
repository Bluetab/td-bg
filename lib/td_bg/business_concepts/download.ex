defmodule TdBg.BusinessConcept.Download do
  @moduledoc """
  Helper module to download business concepts.
  """

  alias TdCache.TemplateCache
  alias TdDfLib.Format
  alias TdDfLib.Parser
  alias TdDfLib.Templates

  @concept_url_insert_at 6

  def to_csv(concepts, header_labels, concept_url_schema \\ nil) do
    concepts_by_type = Enum.group_by(concepts, &(&1 |> Map.get("template") |> Map.get("name")))
    types = Map.keys(concepts_by_type)

    templates_by_type = Enum.reduce(types, %{}, &Map.put(&2, &1, TemplateCache.get_by_name!(&1)))

    list =
      Enum.reduce(types, [], fn type, acc ->
        template = Map.get(templates_by_type, type)

        concepts =
          concepts_by_type
          |> Map.get(type)
          |> Enum.map(&add_completeness(template, &1))

        csv_list =
          template_concepts_to_csv(
            template,
            concepts,
            header_labels,
            !Enum.empty?(acc),
            concept_url_schema
          )

        acc ++ csv_list
      end)

    to_string(list)
  end

  defp add_completeness(%{} = template, %{"content" => content} = bcv),
    do: Map.put(bcv, "completeness", Templates.completeness(content, template))

  defp add_completeness(_, bcv), do: bcv

  defp template_concepts_to_csv(nil, concepts, header_labels, add_separation, concept_url_schema) do
    headers = build_headers(header_labels)
    concepts_list = concepts_to_list(concepts, [], concept_url_schema)
    export_to_csv(headers, concepts_list, add_separation)
  end

  defp template_concepts_to_csv(
         template,
         concepts,
         header_labels,
         add_separation,
         concept_url_schema
       ) do
    content = Format.flatten_content_fields(template.content)
    content_fields = Enum.reduce(content, [], &(&2 ++ [Map.take(&1, ["name", "values", "type"])]))
    content_labels = Enum.reduce(content, [], &(&2 ++ [Map.get(&1, "label")]))
    headers = build_headers(header_labels)
    headers = headers ++ content_labels
    concepts_list = concepts_to_list(concepts, content_fields, concept_url_schema)
    export_to_csv(headers, concepts_list, add_separation)
  end

  defp concepts_to_list(concepts, content_fields, concept_url_schema) do
    Enum.reduce(concepts, [], fn concept, acc ->
      content = concept["content"]

      values =
        [
          concept["template"]["name"],
          concept["name"],
          concept["domain"]["name"],
          concept["status"],
          concept["description"],
          concept["completeness"],
          concept["inserted_at"],
          concept["last_change_at"]
        ]
        |> maybe_add_link_to_concept(concept, concept_url_schema)
        |> Parser.append_parsed_fields(content_fields, content)

      acc ++ [values]
    end)
  end

  defp maybe_add_link_to_concept(values, _concept, nil), do: values

  defp maybe_add_link_to_concept(values, concept, url_schema) do
    if String.contains?(url_schema, ":business_concept_id") and
         String.contains?(url_schema, "/:id") do
      concept_url =
        String.replace(
          url_schema,
          ":business_concept_id",
          to_string(concept["business_concept_id"])
        )
        |> String.replace(":id", to_string(concept["id"]))

      List.insert_at(values, @concept_url_insert_at, concept_url)
    else
      values
    end
  end

  defp export_to_csv(headers, concepts_list, add_separation) do
    list_to_encode =
      case add_separation do
        true ->
          empty = build_empty_list([], length(headers))
          [empty, empty, headers] ++ concepts_list

        false ->
          [headers | concepts_list]
      end

    list_to_encode
    |> CSV.encode(separator: ?;)
    |> Enum.to_list()
  end

  defp build_headers(header_labels) do
    [
      "template",
      "name",
      "domain",
      "status",
      "description",
      "completeness",
      "inserted_at",
      "last_change_at"
    ]
    |> maybe_add_link_to_concept_header(header_labels)
    |> Enum.map(fn h -> Map.get(header_labels, h, h) end)
  end

  defp maybe_add_link_to_concept_header(header_label_list, %{"link_to_concept" => _}) do
    List.insert_at(header_label_list, @concept_url_insert_at, "link_to_concept")
  end

  defp maybe_add_link_to_concept_header(header_label_list, _header_labels), do: header_label_list

  defp build_empty_list(acc, l) when l < 1, do: acc
  defp build_empty_list(acc, l), do: ["" | build_empty_list(acc, l - 1)]
end
