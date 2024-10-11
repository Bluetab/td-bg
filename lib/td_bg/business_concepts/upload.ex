defmodule TdBg.BusinessConcept.Upload do
  @moduledoc """
  Helper module to upload business concepts in csv format.
  """
  import Canada.Can, only: [can?: 3]

  alias Ecto.Changeset
  alias TdBg.BusinessConcepts
  alias TdBg.BusinessConcepts.BusinessConcept
  alias TdBg.BusinessConcepts.BusinessConceptVersion
  alias TdBg.Taxonomies
  alias TdCache.TemplateCache
  alias TdDfLib.Format
  alias TdDfLib.Parser

  require Logger

  @default_lang Application.compile_env(:td_cache, :lang)
  @headers ["id", "name", "domain_external_id", "domain_name", "type", "confidential"]
  @required_headers ["name", "domain_external_id"]
  @required_update_headers ["id"]
  @ignored_headers [
    "domain_name",
    "status",
    "current_version_id",
    "completeness",
    "link_to_concept",
    "last_change_at",
    "inserted_at"
  ]

  def bulk_upload(business_concepts_upload, claims, opts \\ [])

  def bulk_upload(business_concepts_upload, claims, opts) do
    Logger.info("Bulk upload business concepts...")

    Timer.time(
      fn -> do_bulk_upload(business_concepts_upload, claims, opts) end,
      fn ms, _ -> Logger.info("Business concepts inserted in #{ms}ms") end
    )
  end

  def get_headers,
    do: %{
      required: @required_headers,
      update_required: @required_update_headers,
      ignored: @ignored_headers
    }

  defp do_bulk_upload(business_concepts_upload, claims, opts) do
    lang = Keyword.get(opts, :lang, @default_lang)
    auto_publish = Keyword.get(opts, :auto_publish, false)

    with {:ok, data} <- read_xlsx(business_concepts_upload) do
      Enum.reduce(
        data,
        %{created: [], updated: [], errors: []},
        fn %{data: rows, headers: headers, template: template_name}, results ->
          with :ok <- validate_headers(headers),
               {:ok, template} <- validate_template(template_name) do
            rows
            |> Enum.with_index()
            |> Enum.reduce(results, fn row, type_results ->
              row
              |> process_row(headers, claims, auto_publish, template, lang)
              |> put_results(type_results)
            end)
          else
            {:missing_headers_error, missing_headers} ->
              error =
                {:missing_headers_error,
                 %{
                   context: %{headers: missing_headers, type: template_name},
                   message: "concepts.upload.failed.header"
                 }}

              put_errors(results, error)

            {:template_error, :empty_template_name} ->
              error =
                {:empty_template_name, %{message: "concepts.upload.failed.empty_template_name"}}

              put_errors(results, error)

            {:template_error, :template_not_exists} ->
              error =
                {:template_not_exists,
                 %{
                   context: %{template: template_name},
                   message: "concepts.upload.failed.invalid_template"
                 }}

              put_errors(results, error)
          end
        end
      )
    end
  rescue
    err ->
      Logger.error(Exception.format(:error, err, __STACKTRACE__))
      {:error, %{message: :error_processing_file}}
  end

  defp read_xlsx(business_concepts_upload) do
    path = business_concepts_upload.path

    with {:ok, workbook} <- XlsxReader.open(path) do
      workbook
      |> XlsxReader.sheet_names()
      |> Enum.map(fn sheet ->
        # The library parses all numbers as floats by default.
        # The df library will cast the strings to their corresponding type.
        {:ok, [headers | data]} = XlsxReader.sheet(workbook, sheet, number_type: String)

        %{
          template: sheet,
          headers: headers,
          data: data
        }
      end)
      |> then(&{:ok, &1})
    end
  end

  defp process_row({raw_data, index}, headers, claims, auto_publish, template, lang) do
    # ndexing in the data doesn't account for headers, and in XLSX, rows start from 1. That's why
    # we're adding 2 to the index to align it with the XLSX sheet index
    index = index + 2

    row_parsed = parse_row(raw_data, headers, claims, index, template)

    with {:ok, row_parsed} <- validate_and_set_domain(row_parsed),
         :ok <- can_bulk_actions(row_parsed, claims),
         {:ok, row_parsed} <- can_auto_publish(row_parsed, claims, auto_publish),
         :ok <- validate_business_concept_name(row_parsed, template),
         {:ok, row_parsed} <- format_content(row_parsed, template, lang),
         {:ok, row_parsed} <- validate_changeset(row_parsed, template, claims),
         {:ok, row_parsed} <- add_publish_status(row_parsed, claims),
         {:ok, row_parsed} <- upsert(row_parsed) do
      row_parsed
    else
      {:error, :business_concept_not_exists, id} ->
        error =
          {:business_concept_not_exists,
           %{
             context: %{
               id: id,
               type: Map.get(template, :name),
               row: index
             },
             message: "concepts.upload.failed.business_concept_not_exists"
           }}

        put_errors(row_parsed, error)

      {:error, :domain_not_exists, domain_external_id} ->
        error =
          {:domain_not_exists,
           %{
             context: %{
               domain: domain_external_id,
               type: Map.get(template, :name),
               row: index
             },
             message: "concepts.upload.failed.invalid_domain"
           }}

        put_errors(row_parsed, error)

      {:error, :domain_can_not_be_changed, domain} ->
        error =
          {:domain_can_not_be_changed,
           %{
             context: %{
               domain: domain,
               type: Map.get(template, :name),
               row: index
             },
             message: "concepts.upload.failed.domain_changed"
           }}

        put_errors(row_parsed, error)

      {:error, :forbidden_creation, domain_external_id} ->
        error =
          {:forbidden_creation,
           %{
             context: %{
               domain: domain_external_id,
               type: Map.get(template, :name),
               row: index
             },
             message: "concepts.upload.failed.forbidden_creation"
           }}

        put_errors(row_parsed, error)

      {:error, :forbidden_update, domain_external_id} ->
        error =
          {:forbidden_update,
           %{
             context: %{
               domain: domain_external_id,
               type: Map.get(template, :name),
               row: index
             },
             message: "concepts.upload.failed.forbidden_update"
           }}

        put_errors(row_parsed, error)

      {:error, :forbidden_publish, domain_external_id} ->
        error =
          {:forbidden_publish,
           %{
             context: %{
               domain: domain_external_id,
               type: Map.get(template, :name),
               row: index
             },
             message: "concepts.upload.failed.forbidden_publish"
           }}

        put_errors(row_parsed, error)

      {:error, :name_not_available, name} ->
        error =
          {:name_not_available,
           %{
             context: %{
               name: name,
               type: Map.get(template, :name),
               row: index
             },
             message: "concepts.upload.failed.name_not_available"
           }}

        put_errors(row_parsed, error)
    end
  end

  defp format_content_values(content) do
    content
    |> Enum.map(fn {key, value} -> {key, %{"value" => value, "origin" => "file"}} end)
  end

  defp to_valid_id(%{} = params) do
    Map.put(params, "id", to_valid_id(Map.get(params, "id", "")))
  end

  defp to_valid_id(value) when is_binary(value) do
    case Float.parse(value) do
      {num, ""} ->
        num

      _ ->
        ""
    end
  end

  defp to_valid_id(value) when is_number(value), do: value

  defp parse_row(raw_data, headers, %{user_id: user_id}, index, %{name: template_name}) do
    {params, df_content} =
      headers
      |> Enum.zip(raw_data)
      |> Enum.filter(fn {headers, _} -> headers not in @ignored_headers end)
      |> Enum.split_with(fn {headers, _} -> headers in @headers end)
      |> then(fn {params, content} -> {params, format_content_values(content)} end)
      |> then(fn {params, content} -> {Map.new(params), Map.new(content)} end)
      |> then(fn {params, content} -> {to_valid_id(params), content} end)

    action = (is_number(Map.get(params, "id", "")) && :update) || :create

    %{
      params: get_business_concept_base_params(params, user_id),
      action: action,
      versioned: false,
      df_content: df_content,
      changeset: nil,
      business_concept_version: nil,
      index: index,
      template_name: template_name,
      auto_publish: false,
      errors: []
    }
  end

  defp parse_changeset(%{changeset: %{errors: errors, valid?: false} = changeset}, row_parsed) do
    errors =
      errors
      |> Enum.map(fn {field, {error, _}} ->
        {:field_error,
         %{
           context: %{
             row: Map.get(row_parsed, :index),
             type: Map.get(row_parsed, :template_name),
             field: field,
             error: error
           },
           message: "concepts.upload.failed.invalid_field_value"
         }}
      end)

    row_parsed
    |> put_errors(errors)
    |> Map.put(:changeset, changeset)
    |> then(&{:ok, &1})
  end

  defp parse_changeset(%{changeset: %{valid?: true} = changeset}, row_parsed),
    do: {:ok, Map.put(row_parsed, :changeset, changeset)}

  defp format_content(
         %{df_content: content, domain: %{id: domain_id}, params: params} = row_parsed,
         %{content: content_schemas},
         lang
       ) do
    content_schema = Format.flatten_content_fields(content_schemas, lang)
    template_fields = Enum.filter(content_schema, &(Map.get(&1, "type") != "table"))

    fields = Map.keys(content)
    content_schema = Enum.filter(template_fields, &(Map.get(&1, "name") in fields))

    content =
      Parser.format_content(%{
        content: content,
        content_schema: content_schema,
        domain_ids: [domain_id],
        lang: lang
      })

    {:ok,
     %{
       row_parsed
       | params: %{
           params
           | "content" => content,
             "content_schema" => content_schema
         }
     }}
  end

  defp get_business_concept_base_params(params, user_id) do
    id = Map.get(params, "id", "")

    business_concept_attrs =
      %{}
      |> Map.put("last_change_by", user_id)
      |> Map.put("last_change_at", DateTime.utc_now())
      |> Map.put("confidential", convert_confidential(params))

    business_concept_attrs =
      if is_number(id),
        do: Map.put(business_concept_attrs, "id", floor(id)),
        else: Map.delete(business_concept_attrs, "id")

    params
    |> Map.put("business_concept", business_concept_attrs)
    |> Map.put("content_schema", [])
    |> Map.put_new("content", %{})
    |> Map.put("last_change_by", user_id)
    |> Map.put("last_change_at", DateTime.utc_now())
    |> Map.delete("id")
    |> Map.delete("confidential")
  end

  defp can_bulk_actions(%{domain: domain, action: :update}, claims) do
    if can?(claims, :update_business_concept, domain) do
      :ok
    else
      {:error, :forbidden_update, Map.get(domain, :external_id)}
    end
  end

  defp can_bulk_actions(%{domain: domain, action: :create}, claims) do
    if can?(claims, :create_business_concept, domain) do
      :ok
    else
      {:error, :forbidden_creation, Map.get(domain, :external_id)}
    end
  end

  defp can_auto_publish(
         %{domain: domain, params: %{"business_concept" => business_concept} = params} =
           row_parsed,
         claims,
         true = _auto_publish
       ) do
    business_concept_struct =
      business_concept
      |> Map.put("domain_id", domain.id)
      |> Enum.map(fn {key, value} -> {String.to_existing_atom(key), value} end)
      |> then(&struct(BusinessConcept, &1))

    version_fields =
      Enum.map(
        BusinessConceptVersion.__schema__(:fields) ++
          BusinessConceptVersion.__schema__(:associations),
        &to_string/1
      )

    business_concept_version =
      params
      |> Map.put("business_concept", business_concept_struct)
      |> Map.take(version_fields)
      |> Enum.map(fn {key, value} -> {String.to_existing_atom(key), value} end)
      |> then(&struct(BusinessConceptVersion, &1))

    if can?(claims, :auto_publish, business_concept_version) do
      {:ok, Map.put(row_parsed, :auto_publish, true)}
    else
      {:error, :forbidden_publish, Map.get(domain, :external_id)}
    end
  end

  defp can_auto_publish(row_parsed, _claims, false = _auto_publish), do: {:ok, row_parsed}

  defp validate_headers(headers) do
    @required_headers
    |> Enum.into(MapSet.new())
    |> MapSet.difference(Enum.into(headers, MapSet.new()))
    |> MapSet.to_list()
    |> case do
      [] ->
        :ok

      [_ | _] = missing_headers ->
        {:missing_headers_error, missing_headers}
    end
  end

  defp validate_template("" = _template_name),
    do: {:template_error, :empty_template_name}

  defp validate_template(template_name) do
    case TemplateCache.get_by_name!(template_name) do
      nil -> {:template_error, :template_not_exists}
      template -> {:ok, template}
    end
  end

  defp validate_and_set_domain(
         %{params: %{"domain_external_id" => domain_external_id}} = row_parsed
       ) do
    case Taxonomies.get_domain_by_external_id(domain_external_id, [:domain_group]) do
      nil ->
        {:error, :domain_not_exists, domain_external_id}

      domain ->
        validate_domain_not_changed(domain, row_parsed)
    end
  end

  defp validate_domain_not_changed(
         domain,
         %{action: :update, params: %{"business_concept" => %{"id" => id}}} = row_parsed
       ) do
    case BusinessConcepts.get_business_concept(id) do
      nil ->
        {:error, :business_concept_not_exists, id}

      %{domain: %{external_id: external_id}} ->
        if external_id === domain.external_id do
          {:ok, Map.put(row_parsed, :domain, domain)}
        else
          {:error, :domain_can_not_be_changed, domain.external_id}
        end
    end
  end

  defp validate_domain_not_changed(domain, %{action: :create} = row_parsed),
    do: {:ok, Map.put(row_parsed, :domain, domain)}

  defp validate_business_concept_name(
         %{
           params: %{"name" => concept_name},
           domain: %{domain_group: domain_group},
           action: :create
         },
         %{
           name: template_name
         }
       ) do
    case BusinessConcepts.check_business_concept_name_availability(
           template_name,
           concept_name,
           domain_group_id: domain_group && Map.get(domain_group, :id)
         ) do
      {:error, :name_not_available} -> {:error, :name_not_available, concept_name}
      :ok -> :ok
    end
  end

  defp validate_business_concept_name(
         %{
           params: %{"name" => concept_name, "business_concept" => %{"id" => id}},
           domain: %{domain_group: domain_group},
           action: :update
         },
         %{
           name: template_name
         }
       ) do
    case BusinessConcepts.check_business_concept_name_availability(
           template_name,
           concept_name,
           business_concept_id: id,
           domain_group_id: domain_group && Map.get(domain_group, :id)
         ) do
      {:error, :name_not_available} -> {:error, :name_not_available, concept_name}
      :ok -> :ok
    end
  end

  defp validate_changeset(
         %{
           params: params,
           auto_publish: auto_publish,
           domain: %{id: domain_id},
           action: :create
         } = row_parsed,
         %{name: template_name},
         _claims
       ) do
    params
    |> Map.update!("business_concept", fn business_concept ->
      business_concept
      |> Map.put("domain_id", domain_id)
      |> Map.put("type", template_name)
    end)
    |> Map.put("status", get_status(auto_publish))
    |> Map.put("version", 1)
    |> BusinessConcepts.attrs_keys_to_atoms()
    |> BusinessConcepts.new_concept_validations(in_progress: !auto_publish)
    |> parse_changeset(row_parsed)
  end

  defp validate_changeset(
         %{
           params: %{"business_concept" => %{"id" => id}} = params,
           action: :update,
           index: index
         } = row_parsed,
         %{name: template_name},
         %{user_id: user_id} = claims
       ) do
    case BusinessConcepts.get_business_concept_version(id, "latest") do
      nil ->
        error =
          {:business_concept_not_exists,
           %{
             context: %{
               id: id,
               type: template_name,
               row: index
             },
             message: "concepts.upload.failed.invalid_concept"
           }}

        {:ok, put_errors(row_parsed, error)}

      business_concept_version ->
        if can?(claims, :version, business_concept_version) do
          row_parsed = %{
            row_parsed
            | action: :create,
              versioned: true,
              business_concept_version: business_concept_version
          }

          business_concept =
            business_concept_version
            |> Map.get(:business_concept)
            |> Map.put("last_change_by", user_id)
            |> Map.put("last_change_at", DateTime.utc_now())

          params
          |> Map.put("business_concept", business_concept)
          |> Map.put("version", business_concept_version.version + 1)
          |> BusinessConcepts.attrs_keys_to_atoms()
          |> BusinessConcepts.merge_content_with_concept(business_concept_version)
          |> BusinessConcepts.new_concept_validations(
            business_concept_version: business_concept_version,
            in_progress: business_concept_version.status == "draft"
          )
          |> parse_changeset(row_parsed)
        else
          row_parsed = %{
            row_parsed
            | business_concept_version:
                BusinessConcepts.get_business_concept_version(id, "current"),
              versioned: !Map.get(business_concept_version, :current)
          }

          params
          |> BusinessConcepts.attrs_keys_to_atoms()
          |> BusinessConcepts.merge_content_with_concept(business_concept_version)
          |> BusinessConcepts.update_concept_validations(business_concept_version)
          |> parse_changeset(row_parsed)
        end
    end
  end

  defp add_publish_status(
         %{changeset: %{valid?: true} = changeset, auto_publish: true} = row_parsed,
         %{user_id: user_id}
       ) do
    publish_changeset =
      changeset
      |> Changeset.change(status: "published")
      |> Changeset.change(current: true)
      |> BusinessConceptVersion.status_changeset(user_id)

    {:ok, Map.put(row_parsed, :changeset, publish_changeset)}
  end

  defp add_publish_status(%{changeset: %{valid?: false}} = row_parsed, _),
    do: {:ok, row_parsed}

  defp add_publish_status(%{auto_publish: false} = row_parsed, _), do: {:ok, row_parsed}

  defp convert_confidential(%{"confidential" => confidential_value}) do
    confidential_value = String.downcase(confidential_value)

    case confidential_value do
      "si" -> true
      "yes" -> true
      "true" -> true
      _ -> false
    end
  end

  defp convert_confidential(_), do: false

  defp get_status(true = _auto_publish), do: "published"

  defp get_status(false = _auto_publish), do: "draft"

  defp upsert(
         %{
           action: :create,
           errors: [],
           changeset: %{valid?: true},
           versioned: true,
           auto_publish: false
         } = row_parsed
       ) do
    with {:ok, %{current: %{id: id}}} <-
           BusinessConcepts.version_concept(row_parsed) do
      bcv = BusinessConcepts.get_business_concept_version!(id)
      BusinessConcepts.refresh_cache_and_elastic(bcv)
      {:ok, Map.put(row_parsed, :business_concept_version, bcv)}
    end
  end

  defp upsert(
         %{
           business_concept_version: old_business_concept_version,
           action: :create,
           errors: [],
           changeset: %{valid?: true},
           versioned: true,
           auto_publish: true
         } = row_parsed
       ) do
    with {:ok, %{published: %{id: published_id}}} <-
           BusinessConcepts.publish_version_concept(row_parsed) do
      BusinessConcepts.refresh_cache_and_elastic(old_business_concept_version)
      published_bcv = BusinessConcepts.get_business_concept_version!(published_id)
      BusinessConcepts.refresh_cache_and_elastic(published_bcv)

      {:ok, Map.put(row_parsed, :business_concept_version, published_bcv)}
    end
  end

  defp upsert(
         %{
           action: :create,
           errors: [],
           changeset: %{valid?: true},
           versioned: false
         } = row_parsed
       ) do
    with {:ok, %{business_concept_version: %{id: id}}} <-
           BusinessConcepts.insert_concept(row_parsed) do
      bcv = BusinessConcepts.get_business_concept_version!(id)
      BusinessConcepts.refresh_cache_and_elastic(bcv)
      {:ok, Map.put(row_parsed, :business_concept_version, bcv)}
    end
  end

  defp upsert(
         %{
           action: :update,
           auto_publish: true,
           versioned: true,
           business_concept_version: old_business_concept_version,
           errors: [],
           changeset: %{valid?: true}
         } = row_parsed
       ) do
    with {:ok, %{published: %{id: published_id}}} <-
           BusinessConcepts.publish_version_concept(row_parsed) do
      BusinessConcepts.refresh_cache_and_elastic(old_business_concept_version)
      published_bcv = BusinessConcepts.get_business_concept_version!(published_id)
      BusinessConcepts.refresh_cache_and_elastic(published_bcv)

      {:ok, Map.put(row_parsed, :business_concept_version, published_bcv)}
    end
  end

  defp upsert(%{action: :update, errors: [], changeset: %{valid?: true}} = row_parsed) do
    with {:ok, %{updated: %{id: id}}} <-
           BusinessConcepts.update_concept(row_parsed) do
      bcv = BusinessConcepts.get_business_concept_version!(id)
      BusinessConcepts.refresh_cache_and_elastic(bcv)
      {:ok, Map.put(row_parsed, :business_concept_version, bcv)}
    end
  end

  defp upsert(%{errors: [_ | _]} = row_parsed), do: {:ok, row_parsed}

  defp put_errors(item, errors) when is_list(errors) do
    errors
    |> format_errors()
    |> then(fn errors ->
      {_, new_item} = Map.get_and_update(item, :errors, &{&1, &1 ++ errors})
      new_item
    end)
  end

  defp put_errors(item, errors), do: put_errors(item, [errors])

  defp put_results(%{business_concept_version: bcv} = row, result) do
    case row do
      %{errors: [_ | _] = errors} ->
        put_errors(result, errors)

      %{action: :create, versioned: false} ->
        Map.put(result, :created, Map.get(result, :created) ++ [bcv.id])

      %{action: :create, versioned: true} ->
        Map.put(result, :updated, Map.get(result, :updated) ++ [bcv.id])

      %{action: :update} ->
        Map.put(result, :updated, Map.get(result, :updated) ++ [bcv.id])
    end
  end

  defp format_errors(errors) do
    Enum.map(errors, fn
      {type, body} -> %{error_type: Atom.to_string(type), body: body}
      %{body: _, error_type: _} = formated_error -> formated_error
    end)
  end
end
