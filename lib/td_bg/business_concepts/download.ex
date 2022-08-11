defmodule TdBg.BusinessConcept.Download do
  @moduledoc """
  Helper module to download business concepts.
  """

  alias TdCache.TemplateCache
  alias TdDfLib.Format

  def to_csv(concepts, header_labels) do
    concepts_by_type = Enum.group_by(concepts, &(&1 |> Map.get("template") |> Map.get("name")))
    types = Map.keys(concepts_by_type)

    templates_by_type = Enum.reduce(types, %{}, &Map.put(&2, &1, TemplateCache.get_by_name!(&1)))

    list =
      Enum.reduce(types, [], fn type, acc ->
        concepts = Map.get(concepts_by_type, type)
        template = Map.get(templates_by_type, type)

        csv_list = template_concepts_to_csv(template, concepts, header_labels, !Enum.empty?(acc))
        acc ++ csv_list
      end)

    to_string(list)
  end

  defp template_concepts_to_csv(nil, concepts, header_labels, add_separation) do
    headers = build_headers(header_labels)
    concepts_list = concepts_to_list(concepts)
    export_to_csv(headers, concepts_list, add_separation)
  end

  defp template_concepts_to_csv(template, concepts, header_labels, add_separation) do
    content = Format.flatten_content_fields(template.content)
    content_fields = Enum.reduce(content, [], &(&2 ++ [Map.take(&1, ["name", "values", "type"])]))
    content_labels = Enum.reduce(content, [], &(&2 ++ [Map.get(&1, "label")]))
    headers = build_headers(header_labels)
    headers = headers ++ content_labels
    concepts_list = concepts_to_list(concepts, content_fields)
    export_to_csv(headers, concepts_list, add_separation)
  end

  defp concepts_to_list(concepts, content_fields \\ []) do
    Enum.reduce(concepts, [], fn concept, acc ->
      content = concept["content"]

      values = [
        concept["template"]["name"],
        concept["name"],
        concept["domain"]["name"],
        concept["status"],
        concept["description"],
        concept["inserted_at"],
        concept["last_change_at"]
      ]

      acc ++ [Enum.reduce(content_fields, values, &(&2 ++ [&1 |> get_content_field(content)]))]
    end)
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
    ["template", "name", "domain", "status", "description", "inserted_at", "last_change_at"]
    |> Enum.map(fn h -> Map.get(header_labels, h, h) end)
  end

  defp get_url_value(%{"url_value" => url_value}), do: url_value
  defp get_url_value(_), do: nil

  defp get_content_field(%{"type" => "url", "name" => name}, content) do
    content
    |> Map.get(name, [])
    |> content_to_list()
    |> Enum.map(&get_url_value/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.join(", ")
  end

  defp get_content_field(%{"type" => type, "name" => name}, content)
       when type in ["domain", "system"] do
    content
    |> Map.get(name, [])
    |> content_to_list()
    |> Enum.map(&Map.get(&1, "name"))
    |> Enum.reject(&is_nil/1)
    |> Enum.join(", ")
  end

  defp get_content_field(
         %{
           "type" => "string",
           "name" => name,
           "values" => %{"fixed_tuple" => values}
         },
         content
       ) do
    content
    |> Map.get(name, [])
    |> content_to_list()
    |> Enum.map(fn map_value ->
      Enum.find(values, fn %{"value" => value} -> value == map_value end)
    end)
    |> Enum.reject(&is_nil/1)
    |> Enum.map_join(", ", &Map.get(&1, "text", ""))
  end

  defp get_content_field(%{"type" => "table"}, _content), do: ""

  defp get_content_field(%{"name" => name}, content) do
    Map.get(content, name, "")
  end

  defp content_to_list(nil), do: []

  defp content_to_list([""]), do: []

  defp content_to_list(""), do: []

  defp content_to_list(content) when is_list(content), do: content

  defp content_to_list(content), do: [content]

  defp build_empty_list(acc, l) when l < 1, do: acc
  defp build_empty_list(acc, l), do: ["" | build_empty_list(acc, l - 1)]
end
