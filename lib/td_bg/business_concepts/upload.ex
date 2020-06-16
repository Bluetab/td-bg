defmodule TdBg.BusinessConcept.Upload do
  @moduledoc """
  Helper module to upload business concepts in csv format.
  """

  @required_header ["template", "domain", "name", "description"]

  alias Codepagex
  alias NimbleCSV
  alias TdBg.BusinessConcepts
  alias TdBg.BusinessConcepts.Audit
  alias TdBg.Cache.ConceptLoader
  alias TdBg.Repo
  alias TdBg.Taxonomies
  alias TdCache.TemplateCache
  alias TdDfLib.Format

  require Logger

  NimbleCSV.define(ParserCSVUpload, separator: ";")

  def from_csv(nil, _user), do: {:error, %{message: :no_csv_uploaded}}

  def from_csv(business_concept_upload, user) do
    path = business_concept_upload.path

    case create_concepts(path, user) do
      {:ok, concept_ids} ->
        Audit.business_concepts_created(concept_ids)
        ConceptLoader.refresh(concept_ids)
        {:ok, concept_ids}

      error ->
        error
    end
  end

  defp create_concepts(path, user) do
    Logger.info("Inserting business concepts...")

    Timer.time(
      fn -> Repo.transaction(fn -> upload_in_transaction(path, user) end) end,
      fn ms, _ -> Logger.info("Business concepts inserted in #{ms}ms") end
    )
  end

  defp upload_in_transaction(path, user) do
    file =
      path
      |> Path.expand()
      |> File.stream!()

    with {:ok, parsed_file} <- parse_file(file),
         {:ok, parsed_list} <- parse_data_list(parsed_file) ,
         {:ok, uploaded_ids} <- upload_data(parsed_list, user, [], 2) do
      uploaded_ids
    else
      {:error, err} -> Repo.rollback(err)
    end
  end

  defp parse_file(file) do
    parsed_file =
      file
      |> ParserCSVUpload.parse_stream(skip_headers: false)
      |> Enum.to_list()

    {:ok, parsed_file}
  rescue
    _ -> {:error, %{error: :invalid_file_format}}
  end

  defp parse_data_list([headers | tail]) do
    case Enum.reduce(@required_header, true, fn head, acc ->
           Enum.member?(headers, head) and acc
         end) do
      true ->
        parsed_list =
          tail
          |> Enum.map(&decode_rows/1)
          |> Enum.map(&row_list_to_map(headers, &1))

        {:ok, parsed_list}

      false ->
        {:error, %{error: :missing_required_columns, expected: @required_header, found: headers}}
    end
  end

  defp decode_rows(rows) do
    Enum.map(rows, &decode_row/1)
  end

  defp decode_row(row) do
    if String.valid?(row) do
      row
    else
      Codepagex.to_string!(row, "VENDORS/MICSFT/WINDOWS/CP1252", Codepagex.use_utf_replacement())
    end
  end

  defp row_list_to_map(headers, row) do
    headers
    |> Enum.zip(row)
    |> Enum.into(%{})
  end

  defp upload_data([head | tail], user, acc, row_count) do
    case insert_business_concept(head, user) do
      {:ok, %{business_concept_version: %{business_concept_id: concept_id}}} ->
        upload_data(tail, user, [concept_id | acc], row_count + 1)

      {:error, :business_concept_version, error, _} ->
        {:error, Map.put(error, :row, row_count)}
    end
  end

  defp upload_data(_, _, acc, _), do: {:ok, acc}

  defp insert_business_concept(data, user) do
    with {:ok, %{name: concept_type, content: content_schema}} <- validate_template(data),
         {:ok} <- validate_name(data),
         {:ok, %{id: domain_id}} <- validate_domain(data),
         {:ok} <- validate_description(data) do
      empty_fields =
        data
        |> Enum.filter(fn {_field_name, value} -> is_empty?(value) end)
        |> Enum.map(&elem(&1, 0))

      content_schema = Format.flatten_content_fields(content_schema)

      table_fields =
        content_schema
        |> Enum.filter(&(Map.get(&1, "type") == "table"))
        |> Enum.map(&Map.get(&1, "name"))

      content =
        data
        |> Map.drop(["name", "domain", "description", "template"])
        |> Map.drop(empty_fields)
        |> Map.drop(table_fields)

      business_concept_attrs =
        %{}
        |> Map.put("domain_id", domain_id)
        |> Map.put("type", concept_type)
        |> Map.put("last_change_by", user.id)
        |> Map.put("last_change_at", DateTime.utc_now())

      creation_attrs =
        data
        |> Map.take(["name"])
        |> Map.put("description", convert_description(Map.get(data, "description")))
        |> Map.put("content", content)
        |> Map.put("business_concept", business_concept_attrs)
        |> Map.put("content_schema", content_schema)
        |> Map.put("last_change_by", user.id)
        |> Map.put("last_change_at", DateTime.utc_now())
        |> Map.put("status", "draft")
        |> Map.put("version", 1)

      BusinessConcepts.create_business_concept(creation_attrs, [in_progress: false])
    else
      error -> error
    end
  end

  defp is_empty?(nil), do: true
  defp is_empty?(""), do: true
  defp is_empty?(_), do: false

  defp validate_template(%{"template" => ""}),
    do: {:error, %{error: :missing_value, field: "template"}}

  defp validate_template(%{"template" => template}) do
    case TemplateCache.get_by_name!(template) do
      nil -> {:error, %{error: :invalid_template, template: template}}
      template -> {:ok, template}
    end
  end

  defp validate_template(_), do: {:error, %{error: :missing_value, field: "template"}}

  defp validate_name(%{"name" => ""}), do: {:error, %{error: :missing_value, field: "name"}}

  defp validate_name(%{"name" => name, "template" => template}) do
    case BusinessConcepts.check_business_concept_name_availability(template, name) do
      :ok -> {:ok}
      {:error, error} -> {:error, %{error: error, name: name}}
    end
  end

  defp validate_name(_), do: {:error, %{error: :missing_value, field: "name"}}

  defp validate_domain(%{"domain" => ""}), do: {:error, %{error: :missing_value, field: "domain"}}

  defp validate_domain(%{"domain" => domain}) do
    case Taxonomies.get_domain_by_name(domain) do
      nil -> {:error, %{error: :invalid_domain, domain: domain}}
      domain -> {:ok, domain}
    end
  end

  defp validate_domain(_), do: {:error, %{error: :missing_value, field: "domain"}}

  defp validate_description(%{"description" => ""}),
    do: {:error, %{error: :missing_value, field: "description"}}

  defp validate_description(%{"description" => _}), do: {:ok}
  defp validate_description(_), do: {:error, %{error: :missing_value, field: "description"}}

  defp convert_description(description) do
    %{
      document: %{
        nodes: [
          %{
            object: "block",
            type: "paragraph",
            nodes: [%{object: "text", leaves: [%{text: description}]}]
          }
        ]
      }
    }
  end
end
