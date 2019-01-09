defmodule TdBg.BusinessConcept.Upload do
  require Logger

  alias TdDfLib.Validation

  @df_cache Application.get_env(:td_bg, :df_cache)

  @moduledoc """
    Helper module to upload business concepts in csv format.

    curl -H "Content-Type: application/json" -X POST -d '{"user":{"user_name":"xxx","password":"xxx"}}' http://localhost:4001/api/sessions
    curl -H "authorization: Bearer xxx" -F "business_concepts=@business_concepts.csv"  http://localhost:4002/api/business_concept_versions/upload

  """

  # $1 domain name
  # $2 type
  # $3 last_change_by
  # $4 last_change_at, inserted_at, updated_at

  @insert_business_concept """
    INSERT INTO business_concepts (domain_id, "type", last_change_by, last_change_at, inserted_at, updated_at)
    VALUES ((select id from domains where name = $1), $2, $3, $4, $4, $4) RETURNING id;
  """

  # $1 type
  # $2 versioned
  # $3 deprecated
  # $4 name

  @check_name_availability """
    SELECT COUNT(*) FROM business_concepts AS c
    LEFT JOIN business_concept_aliases AS a ON c.id = a.business_concept_id
    LEFT JOIN business_concept_versions AS v on c.id = v.business_concept_id
    WHERE c.type = $1 and v.status NOT IN ($2, $3) AND (v.name = $4 OR a.name = $4)
  """

  # $1 business concept id
  # $2 name
  # $3 description
  # $4 content
  # $5 last_change_by
  # $6 last_change_at, inserted_at, updated_at
  # $7 status
  # $8 version
  # $9 related_to
  # $10 current

  @insert_business_concept_version """
    INSERT INTO business_concept_versions (business_concept_id, name, description, content, last_change_by, last_change_at, status, version, inserted_at, updated_at, related_to, current)
    VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $6, $6, $9, $10) RETURNING id;
  """

  @template "template"
  @domain "domain"

  @name "name"
  @description "description"

  @no_content [@template, @domain, @name, @description]

  alias Codepagex
  alias Ecto.Adapters.SQL
  alias NimbleCSV
  alias Postgrex.Result
  alias TdBg.BusinessConcept.RichText
  alias TdBg.BusinessConceptLoader
  alias TdBg.BusinessConcepts
  alias TdBg.BusinessConcepts.BusinessConcept
  alias TdBg.Repo

  NimbleCSV.define(ParserCSVUpload, separator: ";")

  def from_csv(nil, _user), do: {:error, %{message: :no_csv_uploaded}}

  def from_csv(business_concept_upload, user) do
    path = business_concept_upload.path

    case create_concepts(path, user) do
      {:ok, concepts_ids} ->
        index_concepts(concepts_ids)
        cache_concepts(concepts_ids)
        {:ok, concepts_ids}

      error ->
        error
    end
  end

  defp create_concepts(path, user) do
    Logger.info("Inserting business concepts...")
    start_time = DateTime.utc_now()

    transaction_result =
      Repo.transaction(fn ->
        upload_in_transaction(path, user)
      end)

    end_time = DateTime.utc_now()

    Logger.info(
      "Business concepts inserted. Elapsed seconds: #{DateTime.diff(end_time, start_time)}"
    )

    transaction_result
  end

  defp index_concepts(concept_ids) do
    Logger.info("Indexing business concepts...")
    start_time = DateTime.utc_now()

    Enum.each(concept_ids, &index_concept(&1))

    end_time = DateTime.utc_now()

    Logger.info(
      "Business concepts indexed. Elapsed seconds: #{DateTime.diff(end_time, start_time)}"
    )
  end

  defp cache_concepts(concepts_ids) do
    Logger.info("Caching business concepts...")
    start_time = DateTime.utc_now()

    Enum.each(concepts_ids, &BusinessConceptLoader.refresh(&1))

    end_time = DateTime.utc_now()

    Logger.info(
      "Business concepts cached. Elapsed seconds: #{DateTime.diff(end_time, start_time)}"
    )
  end

  defp index_concept(concept_id) do
    params = BusinessConcepts.retrieve_last_bc_version_params(concept_id)
    BusinessConcepts.index_business_concept_versions(concept_id, params)
  end

  defp upload_in_transaction(path, user) do
    path
    |> Path.expand()
    |> File.stream!()
    |> ParserCSVUpload.parse_stream(headers: false)
    |> Enum.to_list()
    |> parse_data_list()
    |> upload_data(user, [])
  end

  defp parse_data_list([headers | tail]) do
    tail
    |> Enum.map(&parse_uncoded_rows(&1))
    |> Enum.map(&row_list_to_map(headers, &1))
  end

  defp row_list_to_map(headers, row) do
    headers
    |> Enum.zip(row)
    |> Enum.into(%{})
  end

  defp parse_uncoded_rows(fiel_row_list) do
    fiel_row_list
    |> Enum.map(fn row ->
      case String.valid?(row) do
        true ->
          row

        false ->
          Codepagex.to_string!(
            row,
            "VENDORS/MICSFT/WINDOWS/CP1252",
            Codepagex.use_utf_replacement()
          )
      end
    end)
  end

  defp upload_data([head | tail], user, acc) do
    case insert_business_concept(%{data: head, user: user}) do
      {:ok, concept_id} ->
        upload_data(tail, user, [concept_id | acc])

      {:error, value} ->
        Repo.rollback(%{row: head, message: value})
    end
  end

  defp upload_data(_, _, acc), do: acc

  defp insert_business_concept(%{
         data: _data,
         user: user,
         template: template,
         content: content,
         concept_data: concept_data,
         version_data: version_data
       }) do
    now = DateTime.utc_now()
    draft = BusinessConcept.status().draft

    concept_query_input = [concept_data[@domain], template.name, user.id, now]

    %Result{rows: [[concept_id]]} =
      SQL.query!(Repo, @insert_business_concept, concept_query_input)

    version_query_input = [
      concept_id,
      version_data[@name],
      RichText.to_rich_text(version_data[@description]),
      content,
      user.id,
      now,
      draft,
      1,
      [],
      true
    ]

    SQL.query!(Repo, @insert_business_concept_version, version_query_input)

    {:ok, concept_id}
  end

  defp insert_business_concept(%{data: data, user: user, template: template, content: content}) do
    concept_data =
      data
      |> Map.take([@domain])

    version_data =
      data
      |> Map.take([@name, @description])

    case validate_name_availability(template.name, data[@name]) do
      {:ok, _} ->
        nil

        insert_business_concept(%{
          data: data,
          user: user,
          template: template,
          content: content,
          concept_data: concept_data,
          version_data: version_data
        })

      error ->
        error
    end
  end

  defp insert_business_concept(%{data: data, user: user, template: template}) do
    content = Map.drop(data, @no_content)
    content = Enum.reduce(template.content, content, &fill_content(&2, &1))

    case validate_content(content, template) do
      {:ok, content} ->
        insert_business_concept(%{data: data, user: user, template: template, content: content})

      error ->
        error
    end
  end

  defp insert_business_concept(%{data: data, user: user}) do
    case get_template(data) do
      {:ok, template} ->
        insert_business_concept(%{data: data, user: user, template: template})

      error ->
        error
    end
  end

  defp fill_content(content, %{"type" => type, "name" => name}) when type == "variable_list" do
    case Map.get(content, name, nil) do
      nil -> content
      value -> Map.put(content, name, [value])
    end
  end

  defp fill_content(content, _field), do: content

  defp get_template(%{"template" => template}) do
    case @df_cache.get_template_by_name(template) do
      nil -> {:error, :no_template_found}
      template -> {:ok, template}
    end
  end

  defp get_template(_) do
    case @df_cache.get_default_template() do
      nil -> {:error, :no_template_found}
      template -> {:ok, template}
    end
  end

  defp validate_content(content, template) do
    changeset = Validation.build_changeset(content, template.content)

    case changeset.valid? do
      true -> {:ok, content}
      false -> {:error, changeset}
    end
  end

  defp validate_name_availability(type, name) do
    deprecated = BusinessConcept.status().deprecated
    versioned = BusinessConcept.status().versioned

    %Result{rows: [[count]]} =
      SQL.query!(Repo, @check_name_availability, [type, deprecated, versioned, name])

    if count == 0, do: {:ok, count}, else: {:error, :name_not_available}
  end
end
