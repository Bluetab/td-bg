defmodule TdBgWeb.BusinessConceptVersionController do
  use TdBgWeb, :controller
  use TdHypermedia, :controller

  import Canada, only: [can?: 2]
  import Canada.Can, only: [can?: 3]

  alias TdBg.BusinessConcept.BulkUpdate
  alias TdBg.BusinessConcept.Download
  alias TdBg.BusinessConcept.Search
  alias TdBg.BusinessConcepts
  alias TdBg.BusinessConcepts.BulkUploader
  alias TdBg.BusinessConcepts.BulkUploadEvent
  alias TdBg.BusinessConcepts.BusinessConcept
  alias TdBg.BusinessConcepts.BusinessConceptVersion
  alias TdBg.BusinessConcepts.Links
  alias TdBg.BusinessConcepts.Workflow
  alias TdBg.I18nContents.I18nContents
  alias TdBg.Taxonomies
  alias TdBg.Taxonomies.Domain
  alias TdBg.Utils.Hasher
  alias TdBgWeb.ErrorView

  alias TdCache.TagCache
  alias TdCache.TemplateCache
  alias TdDfLib.Format

  require Logger

  action_fallback(TdBgWeb.FallbackController)

  def xlsx(conn, params) do
    claims = conn.assigns[:current_resource]

    {lang, params} = Map.pop(params, "lang", BusinessConcepts.get_default_lang())
    concept_url_schema = Map.get(params, "concept_url_schema", nil)

    %{results: business_concept_versions} =
      Search.search_business_concept_versions(params, claims, 0, 10_000)

    with workbook <- Download.to_xlsx(business_concept_versions, lang, concept_url_schema),
         {:ok, {file_name, file_binary}} <- Elixlsx.write_to_memory(workbook, "concepts.xlsx") do
      conn
      |> put_resp_content_type(
        "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet;charset=utf-8"
      )
      |> put_resp_header("content-disposition", "attachment; filename=#{file_name}")
      |> send_resp(:ok, file_binary)
    end
  end

  def csv(conn, params) do
    claims = conn.assigns[:current_resource]

    {lang, params} = Map.pop(params, "lang", BusinessConcepts.get_default_lang())
    concept_url_schema = Map.get(params, "concept_url_schema", nil)

    %{results: business_concept_versions} =
      Search.search_business_concept_versions(params, claims, 0, 10_000)

    conn
    |> put_resp_content_type("text/csv", "utf-8")
    |> put_resp_header("content-disposition", "attachment; filename=\"concepts.csv\"")
    |> send_resp(
      :ok,
      Download.to_csv(business_concept_versions, lang, concept_url_schema)
    )
  end

  def upload(conn, params) do
    claims = conn.assigns[:current_resource]
    {lang, params} = Map.pop(params, "lang", BusinessConcepts.get_default_lang())
    business_concepts_upload = Map.get(params, "business_concepts")

    auto_publish = params |> Map.get("auto_publish", "false") |> String.to_existing_atom()

    with {:can, true} <- {:can, can?(claims, upload(BusinessConcept))},
         file_hash <- Hasher.hash_file(business_concepts_upload.path) do
      {code, response} =
        case BulkUploader.bulk_upload(
               file_hash,
               business_concepts_upload,
               claims,
               auto_publish,
               lang
             ) do
          {:started, ^file_hash, task_reference} ->
            {
              :accepted,
              %{file_hash: file_hash, status: "STARTED", task_reference: task_reference}
            }

          {:running, %BulkUploadEvent{file_hash: ^file_hash} = event} ->
            {:accepted,
             TdBgWeb.BulkUploadEventView.render("show.json", %{bulk_upload_event: event})}
        end

      conn
      |> put_resp_content_type("application/json", "utf-8")
      |> send_resp(code, Jason.encode!(response))
    end
  end

  defp get_flat_template_content(%{content: content}) do
    Format.flatten_content_fields(content)
  end

  defp get_flat_template_content(_), do: []

  def create(conn, %{"business_concept_version" => business_concept_params}) do
    %{user_id: user_id} = claims = conn.assigns[:current_resource]

    # validate fields that if not present are throwing internal server errors in bc creation
    validate_required_bc_fields(business_concept_params)

    concept_type = Map.get(business_concept_params, "type")
    template = TemplateCache.get_by_name!(concept_type)

    content_schema = get_flat_template_content(template)

    concept_name = Map.get(business_concept_params, "name")

    domain_id = Map.get(business_concept_params, "domain_id")
    domain = Taxonomies.get_domain!(domain_id, [:domain_group])
    domain_group_id = get_domain_group_id(domain)

    business_concept_attrs =
      %{}
      |> Map.put("domain_id", domain_id)
      |> Map.put("type", concept_type)
      |> Map.put("last_change_by", user_id)
      |> Map.put("last_change_at", DateTime.utc_now())

    creation_attrs =
      business_concept_params
      |> Map.put("business_concept", business_concept_attrs)
      |> Map.put("content_schema", content_schema)
      |> Map.update("content", %{}, & &1)
      |> Map.put("last_change_by", user_id)
      |> Map.put("last_change_at", DateTime.utc_now())
      |> Map.put("status", "draft")
      |> Map.put("version", 1)

    with {:can, true} <- {:can, can?(claims, create_business_concept(domain))},
         :ok <-
           BusinessConcepts.check_business_concept_name_availability(concept_type, concept_name,
             domain_group_id: domain_group_id
           ),
         {:ok,
          %BusinessConceptVersion{id: id, business_concept_id: business_concept_id} = version} <-
           BusinessConcepts.create_business_concept(creation_attrs, index: true) do
      version = maybe_add_i18n_content(version)

      conn
      |> put_status(:created)
      |> put_resp_header(
        "location",
        Routes.business_concept_business_concept_version_path(
          conn,
          :show,
          business_concept_id,
          id
        )
      )
      |> render("show.json", business_concept_version: version, template: template)
    else
      error -> handle_bc_errors(conn, error)
    end
  rescue
    validation_error in ValidationError ->
      conn
      |> put_status(:unprocessable_entity)
      |> json(%{errors: %{validation_error.field => [validation_error.error]}})
  end

  defp validate_required_bc_fields(attrs) do
    if not Map.has_key?(attrs, "content") do
      raise ValidationError, field: "content", error: "blank"
    end

    if not Map.has_key?(attrs, "type") do
      raise ValidationError, field: "type", error: "blank"
    end
  end

  def show(conn, %{"business_concept_id" => concept_id, "id" => version}) do
    claims = conn.assigns[:current_resource]

    with %BusinessConcept{id: id} <- BusinessConcepts.get_business_concept(concept_id),
         %BusinessConceptVersion{} = business_concept_version <-
           BusinessConcepts.get_business_concept_version(id, version),
         {:can, true} <- {:can, can?(claims, view_business_concept(business_concept_version))} do
      render_concept(conn, business_concept_version)
    else
      nil -> {:error, :not_found}
      error -> error
    end
  end

  defp add_counts(%BusinessConceptVersion{} = business_concept_version) do
    counts = BusinessConcepts.get_concept_counts(business_concept_version.business_concept_id)
    Map.merge(business_concept_version, counts)
  end

  defp add_taxonomy(%BusinessConceptVersion{} = business_concept_version) do
    BusinessConcepts.add_parents(business_concept_version)
  end

  defp add_shared_to_parents(
         %BusinessConceptVersion{business_concept: %{shared_to: shared_to} = concept} =
           business_concept_version
       ) do
    %{
      business_concept_version
      | business_concept: %{concept | shared_to: Taxonomies.add_parents(shared_to)}
    }
  end

  defp links_hypermedia(conn, links, business_concept_version) do
    collection_hypermedia(
      "business_concept_version_business_concept_link",
      conn,
      Enum.map(links, &annotate(&1, business_concept_version)),
      Link
    )
  end

  defp annotate(link, %BusinessConceptVersion{
         id: business_concept_version_id,
         business_concept: %{domain_id: domain_id, shared_to: shared_to}
       }) do
    link
    |> Map.put(:shared_to, shared_to)
    |> Map.put(:business_concept_version_id, business_concept_version_id)
    |> Map.put_new(:domain_id, domain_id)
    |> Map.put(:hint, :link)
  end

  def get_actions(claims, %BusinessConceptVersion{business_concept: concept}) do
    %{share: can_share_concepts(claims, concept)}
    |> maybe_add_implementation_actions(claims, concept)
  end

  defp maybe_add_implementation_actions(actions, claims, concept) do
    [:create_implementation, :create_raw_implementation, :create_link_implementation]
    |> Enum.filter(&can?(claims, &1, concept))
    |> Enum.reduce(%{}, &Map.put(&2, &1, %{method: "POST"}))
    |> Map.merge(actions)
  end

  defp can_share_concepts(claims, concept) do
    if can?(claims, share_with_domain(concept)) do
      %{
        href: "/api/business_concepts/#{concept.id}/shared_domains",
        method: "PATCH",
        input: %{}
      }
    else
      false
    end
  end

  def delete(conn, %{"id" => id}) do
    claims = conn.assigns[:current_resource]
    business_concept_version = BusinessConcepts.get_business_concept_version!(id)

    with {:can, true} <- {:can, can?(claims, delete(business_concept_version))},
         {:ok, %BusinessConceptVersion{}} <-
           BusinessConcepts.delete_business_concept_version(business_concept_version, claims) do
      send_resp(conn, :no_content, "")
    end
  end

  def send_for_approval(conn, %{"business_concept_version_id" => id}) do
    claims = conn.assigns[:current_resource]
    business_concept_version = BusinessConcepts.get_business_concept_version!(id)

    case {business_concept_version.status, BusinessConcepts.last?(business_concept_version)} do
      {"draft", true} ->
        send_for_approval(conn, claims, business_concept_version)

      _ ->
        conn
        |> put_status(:unprocessable_entity)
        |> put_view(ErrorView)
        |> render("422.json")
    end
  end

  def restore(conn, %{"business_concept_version_id" => id}) do
    claims = conn.assigns[:current_resource]
    business_concept_version = BusinessConcepts.get_business_concept_version!(id)

    case {business_concept_version.status, BusinessConcepts.last?(business_concept_version)} do
      {"deprecated", true} ->
        do_publish(conn, claims, business_concept_version)

      _ ->
        conn
        |> put_status(:unprocessable_entity)
        |> put_view(ErrorView)
        |> render("422.json")
    end
  end

  def publish(conn, %{"business_concept_version_id" => id}) do
    claims = conn.assigns[:current_resource]
    business_concept_version = BusinessConcepts.get_business_concept_version!(id)

    case {business_concept_version.status, BusinessConcepts.last?(business_concept_version)} do
      {"pending_approval", true} ->
        do_publish(conn, claims, business_concept_version)

      {"deprecated", true} ->
        do_publish(conn, claims, business_concept_version)

      _ ->
        conn
        |> put_status(:unprocessable_entity)
        |> put_view(ErrorView)
        |> render("422.json")
    end
  end

  def reject(conn, %{"business_concept_version_id" => id} = params) do
    claims = conn.assigns[:current_resource]
    business_concept_version = BusinessConcepts.get_business_concept_version!(id)

    case {business_concept_version.status, BusinessConcepts.last?(business_concept_version)} do
      {"pending_approval", true} ->
        do_reject(conn, claims, business_concept_version, Map.get(params, "reject_reason"))

      _ ->
        conn
        |> put_status(:unprocessable_entity)
        |> put_view(ErrorView)
        |> render("422.json")
    end
  end

  def undo_rejection(conn, %{"business_concept_version_id" => id}) do
    claims = conn.assigns[:current_resource]
    business_concept_version = BusinessConcepts.get_business_concept_version!(id)

    case {business_concept_version.status, BusinessConcepts.last?(business_concept_version)} do
      {"rejected", true} ->
        undo_rejection(conn, claims, business_concept_version)

      _ ->
        conn
        |> put_status(:unprocessable_entity)
        |> put_view(ErrorView)
        |> render("422.json")
    end
  end

  def version(conn, %{"business_concept_version_id" => id}) do
    claims = conn.assigns[:current_resource]
    business_concept_version = BusinessConcepts.get_business_concept_version!(id)

    case {business_concept_version.status, BusinessConcepts.last?(business_concept_version)} do
      {"published", true} ->
        do_version(conn, claims, business_concept_version)

      _ ->
        conn
        |> put_status(:unprocessable_entity)
        |> put_view(ErrorView)
        |> render("422.json")
    end
  end

  def deprecate(conn, %{"business_concept_version_id" => id}) do
    claims = conn.assigns[:current_resource]
    business_concept_version = BusinessConcepts.get_business_concept_version!(id)

    case {business_concept_version.status, business_concept_version.current} do
      {"published", true} ->
        deprecate(conn, claims, business_concept_version)

      _ ->
        conn
        |> put_status(:unprocessable_entity)
        |> put_view(ErrorView)
        |> render("422.json")
    end
  end

  defp add_completeness(%{content: content} = business_concept_version) do
    case BusinessConcepts.get_completeness(business_concept_version, content) do
      c -> Map.put(business_concept_version, :completeness, c)
    end
  end

  defp maybe_add_i18n_content_completeness(
         %{content: content, i18n_content: i18n_content} = bcv,
         template
       ) do
    i18n_content_with_completeness =
      i18n_content
      |> merge_content_with_i18n_content(content, template)
      |> Enum.map(fn %{merged_content: merged_content} = i18n_content ->
        completeness = BusinessConcepts.get_completeness(bcv, merged_content)
        Map.put(i18n_content, :completeness, completeness)
      end)

    Map.put(bcv, :i18n_content, i18n_content_with_completeness)
  end

  defp maybe_add_i18n_content_completeness(bcv, _template), do: bcv

  defp send_for_approval(conn, claims, business_concept_version) do
    with {:can, true} <- {:can, can?(claims, send_for_approval(business_concept_version))},
         {:ok, %{updated: business_concept_version}} <-
           Workflow.submit_business_concept_version(business_concept_version, claims) do
      render_concept(conn, business_concept_version)
    end
  end

  defp undo_rejection(conn, claims, business_concept_version) do
    with {:can, true} <- {:can, can?(claims, undo_rejection(business_concept_version))},
         {:ok, %{updated: business_concept_version}} <-
           Workflow.undo_rejected_business_concept_version(business_concept_version, claims) do
      render_concept(conn, business_concept_version)
    end
  end

  defp deprecate(conn, claims, business_concept_version) do
    with {:can, true} <- {:can, can?(claims, deprecate(business_concept_version))},
         {:ok, %{updated: business_concept_version}} <-
           Workflow.deprecate_business_concept_version(business_concept_version, claims) do
      render_concept(conn, business_concept_version)
    end
  end

  defp do_publish(
         conn,
         claims,
         %{
           name: concept_name,
           business_concept: %{id: id, domain: domain} = business_concept,
           status: status
         } = business_concept_version
       ) do
    %{name: concept_type} = BusinessConcepts.get_template(business_concept)
    domain_group_id = get_domain_group_id(domain)

    can_publish =
      case status do
        "deprecated" -> {:can, can?(claims, restore(business_concept_version))}
        _ -> {:can, can?(claims, publish(business_concept_version))}
      end

    with {:can, true} <- can_publish,
         :ok <-
           BusinessConcepts.check_business_concept_name_availability(concept_type, concept_name,
             business_concept_id: id,
             domain_group_id: domain_group_id
           ),
         {:ok, %{published: %BusinessConceptVersion{} = concept}} <-
           Workflow.publish(business_concept_version, claims) do
      render_concept(conn, concept)
    else
      error -> handle_bc_errors(conn, error)
    end
  end

  defp do_reject(conn, claims, business_concept_version, reason) do
    with {:can, true} <- {:can, can?(claims, reject(business_concept_version))},
         {:ok, %{rejected: %BusinessConceptVersion{} = version}} <-
           Workflow.reject(business_concept_version, reason, claims) do
      render_concept(conn, version)
    end
  end

  defp do_version(conn, claims, business_concept_version) do
    with {:can, true} <- {:can, can?(claims, version(business_concept_version))},
         {:ok, %{current: %BusinessConceptVersion{} = new_version}} <-
           Workflow.new_version(business_concept_version, claims) do
      conn = put_status(conn, :created)
      render_concept(conn, new_version)
    end
  end

  def update(
        conn,
        %{"id" => id, "business_concept_version" => business_concept_version_params}
      ) do
    %{user_id: user_id} = claims = conn.assigns[:current_resource]

    business_concept_version = BusinessConcepts.get_business_concept_version!(id)

    domain_group_id =
      business_concept_version
      |> Map.get(:business_concept)
      |> Map.get(:domain)
      |> get_domain_group_id()

    concept_name = Map.get(business_concept_version_params, "name")
    template = BusinessConcepts.get_template(business_concept_version)

    content_schema = get_flat_template_content(template)

    business_concept_attrs =
      %{}
      |> Map.put("last_change_by", user_id)
      |> Map.put("last_change_at", DateTime.utc_now())

    update_params =
      business_concept_version_params
      |> Map.put("business_concept", business_concept_attrs)
      |> Map.put("content_schema", content_schema)
      |> Map.put_new("content", %{})
      |> Map.put("last_change_by", user_id)
      |> Map.put("last_change_at", DateTime.utc_now())

    with {:can, true} <- {:can, can?(claims, update(business_concept_version))},
         :ok <-
           BusinessConcepts.check_business_concept_name_availability(
             template.name,
             concept_name,
             business_concept_id: business_concept_version.business_concept.id,
             domain_group_id: domain_group_id
           ),
         {:ok, %BusinessConceptVersion{} = concept_version} <-
           BusinessConcepts.update_business_concept_version(
             business_concept_version,
             update_params
           ) do
      concept_version = maybe_add_i18n_content(concept_version)

      render(
        conn,
        "show.json",
        business_concept_version: concept_version,
        hypermedia: hypermedia("business_concept_version", conn, concept_version),
        template: template
      )
    else
      error -> handle_bc_errors(conn, error)
    end
  end

  def update_domain(
        conn,
        %{"business_concept_version_id" => id, "domain_id" => domain_id}
      ) do
    %{user_id: user_id} = claims = conn.assigns[:current_resource]

    business_concept_version = BusinessConcepts.get_business_concept_version!(id)

    domain_before =
      business_concept_version
      |> Map.get(:business_concept)
      |> Map.get(:domain)

    domain_after = Taxonomies.get_domain!(domain_id)

    business_concept_attrs =
      %{}
      |> Map.put("last_change_by", user_id)
      |> Map.put("last_change_at", DateTime.utc_now())
      |> Map.put("domain_id", domain_id)

    update_params = %{"business_concept" => business_concept_attrs}

    with {:can, true} <- {:can, can?(claims, manage_business_concepts_domain(domain_before))},
         {:can, true} <- {:can, can?(claims, manage_business_concepts_domain(domain_after))},
         {:ok, %BusinessConceptVersion{} = concept_version} <-
           BusinessConcepts.update_business_concept(
             business_concept_version,
             update_params
           ) do
      render_concept(conn, concept_version)
    else
      error -> handle_bc_errors(conn, error)
    end
  end

  def set_confidential(conn, %{
        "business_concept_version_id" => id,
        "confidential" => confidential
      }) do
    %{user_id: user_id} = claims = conn.assigns[:current_resource]

    %{business_concept: business_concept} =
      business_concept_version = BusinessConcepts.get_business_concept_version!(id)

    template = BusinessConcepts.get_template(business_concept_version)

    business_concept_attrs = %{
      "last_change_by" => user_id,
      "last_change_at" => DateTime.utc_now(),
      "confidential" => confidential
    }

    update_params = %{"business_concept" => business_concept_attrs}

    with {:can, true} <-
           {:can,
            can?(claims, update(business_concept)) &&
              can?(claims, set_confidential(business_concept_version))},
         {:ok, %BusinessConceptVersion{} = concept_version} <-
           BusinessConcepts.update_business_concept(
             business_concept_version,
             update_params
           ) do
      render(
        conn,
        "show.json",
        business_concept_version: concept_version,
        hypermedia: hypermedia("business_concept_version", conn, concept_version),
        template: template
      )
    end
  end

  def bulk_update(conn, %{
        "update_attributes" => update_attributes,
        "search_params" => search_params
      }) do
    claims = conn.assigns[:current_resource]

    with {:can, true} <- {:can, can?(claims, bulk_update(BusinessConcept))},
         %{results: results} <- search_all_business_concept_versions(claims, search_params),
         {:ok, response} <- BulkUpdate.update_all(claims, results, update_attributes) do
      body = Jason.encode!(%{data: %{message: response}})

      conn
      |> put_resp_content_type("application/json", "utf-8")
      |> send_resp(:ok, body)
    else
      {:can, false} ->
        conn
        |> put_status(:forbidden)
        |> put_view(ErrorView)
        |> render("403.json")

      {:error, error} ->
        Logger.info("While updating business concepts... #{inspect(error)}")

        {:error, error}

      error ->
        Logger.info("Unexpected error while updating business concepts... #{inspect(error)}")

        error
    end
  end

  defp search_all_business_concept_versions(claims, params) do
    params
    |> Map.drop(["page", "size"])
    |> Search.search_business_concept_versions(claims, 0, 10_000)
  end

  defp handle_bc_errors(conn, error) do
    error =
      case error do
        {:error, _field, changeset, _changes_so_far} -> {:error, changeset}
        _ -> error
      end

    case error do
      {:can, false} ->
        conn
        |> put_status(:forbidden)
        |> put_view(ErrorView)
        |> render("403.json")

      {:error, :name_not_available} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: [%{code: "EBG001", name: "concept.error.existing.business.concept"}]})

      {:error, %Ecto.Changeset{data: data} = changeset} ->
        case data do
          %BusinessConceptVersion{} ->
            conn
            |> put_status(:unprocessable_entity)
            |> put_view(TdBgWeb.ChangesetView)
            |> render("error.json",
              changeset: changeset,
              prefix: "concept.error"
            )

          _ ->
            conn
            |> put_status(:unprocessable_entity)
            |> put_view(TdBgWeb.ChangesetView)
            |> render("error.json",
              changeset: changeset,
              prefix: "concept.content.error"
            )
        end

      error ->
        Logger.error("Business concept... #{inspect(error)}")

        conn
        |> put_status(:unprocessable_entity)
        |> put_view(ErrorView)
        |> render("422.json")
    end
  end

  defp get_domain_group_id(%{domain_group: nil}), do: nil

  defp get_domain_group_id(%{domain_group: domain_group}), do: Map.get(domain_group, :id)

  defp render_concept(conn, business_concept_version) do
    claims = conn.assigns[:current_resource]
    locale = conn.assigns[:locale]
    template = BusinessConcepts.get_template(business_concept_version)

    business_concept_version =
      business_concept_version
      |> add_completeness()
      |> add_counts()
      |> add_taxonomy()
      |> add_shared_to_parents()
      |> maybe_add_i18n_content()
      |> maybe_add_i18n_content_completeness(template)

    expandable_tags = TagCache.list_types(expandable: "true")

    original_links =
      Links.get_links(business_concept_version,
        lang: locale,
        without_parent_business_concepts: true
      )

    linked_links =
      original_links
      |> Enum.filter(fn
        %{resource_type: :concept, tags: tags} ->
          length(expandable_tags -- expandable_tags -- tags) > 0

        _ ->
          false
      end)
      |> Enum.flat_map(fn data ->
        data
        |> Map.get(:resource_id)
        |> Links.get_links(lang: locale)
        |> Enum.map(
          &(&1
            |> Map.put(:business_concept_name, data.name)
            |> Map.put(:business_concept_id, data.resource_id))
        )
      end)

    links =
      original_links
      |> Enum.concat(linked_links)
      |> Enum.filter(fn link -> filter_link_by_permission(claims, link) end)

    actions = get_actions(claims, business_concept_version)

    shared_to =
      business_concept_version
      |> Map.get(:business_concept)
      |> Map.get(:shared_to)

    render(
      conn,
      "show.json",
      business_concept_version: business_concept_version,
      links: links,
      shared_to: shared_to,
      links_hypermedia: links_hypermedia(conn, links, business_concept_version),
      hypermedia: hypermedia("business_concept_version", conn, business_concept_version),
      template: template,
      actions: actions
    )
  end

  def filter_link_by_permission(claims, %{resource_type: :data_structure, domain_id: ""}),
    do: can?(claims, view_data_structure(:no_domain))

  def filter_link_by_permission(claims, %{resource_type: :data_structure, domain_ids: domain_ids}),
    do: can?(claims, view_data_structure(domain_ids))

  def filter_link_by_permission(claims, %{resource_type: :data_structure}),
    do: can?(claims, view_data_structure(:no_domain))

  def filter_link_by_permission(claims, %{resource_type: :implementation, domain_id: domain_id}),
    do: can?(claims, view_quality_rule(%Domain{id: domain_id}))

  def filter_link_by_permission(_claims, _), do: false

  defp maybe_add_i18n_content(%{id: bcv_id} = bcv) do
    case I18nContents.get_all_i18n_content_by_bcv_id(bcv_id) do
      [] -> bcv
      i18n_content -> Map.put(bcv, :i18n_content, i18n_content)
    end
  end

  defp merge_content_with_i18n_content(i18n_content, bc_content, %{content: schema}) do
    not_string_template_keys =
      schema
      |> Format.flatten_content_fields()
      |> Enum.filter(fn
        %{"widget" => widget}
        when widget not in ["enriched_text", "string"] ->
          true

        _ ->
          false
      end)
      |> Enum.reduce([], fn %{"name" => name}, acc ->
        [name | acc]
      end)

    not_string_values =
      Enum.filter(bc_content, fn {name, _} ->
        name in not_string_template_keys
      end)
      |> Map.new()

    Enum.map(i18n_content, fn %{content: content} = i18n_content ->
      new_content = Map.merge(not_string_values, content)
      Map.put(i18n_content, :merged_content, new_content)
    end)
  end
end
