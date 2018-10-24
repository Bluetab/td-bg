defmodule TdBgWeb.BusinessConceptVersionController do
  require Logger
  use TdBgWeb, :controller
  use TdBg.Hypermedia, :controller
  use PhoenixSwagger

  import Canada, only: [can?: 2]

  alias TdBg.Audit
  alias TdBg.BusinessConcept.Download
  alias TdBg.BusinessConcept.Search
  alias TdBg.BusinessConcept.Upload
  alias TdBg.BusinessConcepts
  alias TdBg.BusinessConcepts.BusinessConcept
  alias TdBg.BusinessConcepts.BusinessConceptVersion
  alias TdBg.Repo
  alias TdBg.Taxonomies
  alias TdBg.Utils.CollectionUtils
  alias TdBgWeb.BusinessConceptSupport
  alias TdBgWeb.DataFieldView
  alias TdBgWeb.DataStructureView
  alias TdBgWeb.ErrorView
  alias TdBgWeb.SwaggerDefinitions
  alias TdBgWeb.TemplateSupport
  alias TdDf.Templates

  @td_dd_api Application.get_env(:td_bg, :dd_service)[:api_service]

  @events %{
    create_concept_draft: "create_concept_draft",
    update_concept_draft: "update_concept_draft",
    delete_concept_draft: "delete_concept_draft",
    new_concept_draft: "new_concept_draft",
    concept_sent_for_approval: "concept_sent_for_approval",
    concept_rejected: "concept_rejected",
    concept_rejection_canceled: "concept_rejection_canceled",
    concept_published: "concept_published",
    concept_deprecated: "concept_deprecated"
  }

  action_fallback(TdBgWeb.FallbackController)

  def swagger_definitions do
    SwaggerDefinitions.business_concept_version_definitions()
  end

  swagger_path :index do
    description("Business Concept Versions")

    parameters do
      search(
        :body,
        Schema.ref(:BusinessConceptVersionFilterRequest),
        "Search query and filter parameters"
      )
    end

    response(200, "OK", Schema.ref(:BusinessConceptVersionsResponse))
  end

  def index(conn, params) do
    user = conn.assigns[:current_user]

    params
    |> Search.search_business_concept_versions(user)
    |> render_search_results(conn)
  end

  swagger_path :search do
    description("Business Concept Versions")

    parameters do
      search(
        :body,
        Schema.ref(:BusinessConceptVersionFilterRequest),
        "Search query and filter parameters"
      )
    end

    response(200, "OK", Schema.ref(:BusinessConceptVersionsResponse))
  end

  def search(conn, params) do
    user = conn.assigns[:current_user]
    page = params |> Map.get("page", 0)
    size = params |> Map.get("size", 50)

    params
    |> Map.drop(["page", "size"])
    |> Search.search_business_concept_versions(user, page, size)
    |> render_search_results(conn)
  end

  defp render_search_results(%{results: business_concept_versions, total: total}, conn) do
    hypermedia =
      collection_hypermedia(
        "business_concept_version",
        conn,
        business_concept_versions,
        BusinessConceptVersion
      )

    conn
    |> put_resp_header("x-total-count", "#{total}")
    |> render(
      "list.json",
      business_concept_versions: business_concept_versions,
      hypermedia: hypermedia
    )
  end

  def csv(conn, params) do
    user = conn.assigns[:current_user]

    %{results: business_concept_versions} =
      Search.search_business_concept_versions(params, user, 0, 10_000)

    conn
    |> put_resp_content_type("text/csv", "utf-8")
    |> put_resp_header("content-disposition", "attachment; filename=\"concepts.zip\"")
    |> send_resp(200, Download.to_csv(business_concept_versions))
  end

  def upload(conn, params) do
    user = conn.assigns[:current_user]
    business_concepts_upload = Map.get(params, "business_concepts")

    with true <- user.is_admin,
         {:ok, response} <- Upload.from_csv(business_concepts_upload, user) do
      body = Poison.encode!(%{data: %{message: response}})
      send_resp(conn, 200, body)
    else
      false ->
        conn
        |> put_status(:forbidden)
        |> render(ErrorView, "403.json")

      {:error, error} ->
        Logger.error("While uploading business concepts... #{inspect(error)}")

        conn
        |> put_status(:unprocessable_entity)
        |> send_resp(422, Poison.encode!(error))

      error ->
        Logger.error("While uploading business concepts... #{inspect(error)}")

        conn
        |> put_status(:unprocessable_entity)
        |> render(ErrorView, "422.json")
    end
  rescue
    e in RuntimeError ->
      Logger.error("While uploading business concepts... #{e.message}")
      send_resp(conn, :unprocessable_entity, Poison.encode!(%{error: e.message}))
  end

  swagger_path :create do
    description("Creates a Business Concept version child of Data Domain")
    produces("application/json")

    parameters do
      business_concept(
        :body,
        Schema.ref(:BusinessConceptVersionCreate),
        "Business Concept create attrs"
      )
    end

    response(201, "Created", Schema.ref(:BusinessConceptVersionResponse))
    response(400, "Client Error")
  end

  def create(conn, %{"business_concept_version" => business_concept_params}) do
    user = conn.assigns[:current_user]

    # validate fields that if not present are throwing internal server errors in bc creation
    validate_required_bc_fields(business_concept_params)

    concept_type = Map.get(business_concept_params, "type")
    template = Templates.get_template_by_name(concept_type)
    content_schema = Map.get(template, :content)

    concept_name = Map.get(business_concept_params, "name")

    domain_id = Map.get(business_concept_params, "domain_id")
    domain = Taxonomies.get_domain!(domain_id)

    parent_id = Map.get(business_concept_params, "parent_id", nil)

    business_concept_attrs =
      %{}
      |> Map.put("domain_id", domain_id)
      |> Map.put("parent_id", parent_id)
      |> Map.put("type", concept_type)
      |> Map.put("last_change_by", user.id)
      |> Map.put("last_change_at", DateTime.utc_now())

    creation_attrs =
      business_concept_params
      |> Map.put("business_concept", business_concept_attrs)
      |> Map.put("content_schema", content_schema)
      |> Map.update("content", %{}, & &1)
      |> Map.update("related_to", [], & &1)
      |> Map.put("last_change_by", conn.assigns.current_user.id)
      |> Map.put("last_change_at", DateTime.utc_now())
      |> Map.put("status", BusinessConcept.status().draft)
      |> Map.put("version", 1)

    related_to = Map.get(creation_attrs, "related_to")

    with true <- can?(user, create_business_concept(domain)),
         {:name_available} <-
           BusinessConcepts.check_business_concept_name_availability(concept_type, concept_name),
         {:valid_related_to} <- check_valid_related_to(concept_type, related_to),
         {:ok, %BusinessConceptVersion{} = version} <-
           BusinessConcepts.create_business_concept(creation_attrs) do
      business_concept_id = version.business_concept.id

      audit = %{
        "audit" => %{
          "resource_id" => business_concept_id,
          "resource_type" => "business_concept",
          "payload" => creation_attrs
        }
      }

      Audit.create_event(conn, audit, @events.create_concept_draft)

      conn =
        conn
        |> put_status(:created)
        |> put_resp_header(
          "location",
          business_concept_path(conn, :show, version.business_concept)
        )
        |> render(
          "show.json",
          business_concept_version: version,
          template: template
        )

      conn
    else
      error ->
        BusinessConceptSupport.handle_bc_errors(conn, error)
    end
  rescue
    validation_error in ValidationError ->
      conn
      |> put_status(:unprocessable_entity)
      |> json(%{errors: %{"#{validation_error.field}": [validation_error.error]}})
  end

  defp validate_required_bc_fields(attrs) do
    if not Map.has_key?(attrs, "content") do
      raise ValidationError, field: "content", error: "blank"
    end

    if not Map.has_key?(attrs, "type") do
      raise ValidationError, field: "type", error: "blank"
    end
  end

  defp check_valid_related_to(_type, []), do: {:valid_related_to}

  defp check_valid_related_to(type, ids) do
    input_count = length(ids)
    actual_count = BusinessConcepts.count_published_business_concepts(type, ids)
    if input_count == actual_count, do: {:valid_related_to}, else: {:not_valid_related_to}
  end

  swagger_path :versions do
    description("List Business Concept Versions")

    parameters do
      business_concept_version_id(:path, :integer, "Business Concept Version ID", required: true)
    end

    response(200, "OK", Schema.ref(:BusinessConceptVersionsResponse))
  end

  def versions(conn, %{"business_concept_version_id" => business_concept_version_id}) do
    user = conn.assigns[:current_user]

    business_concept_version =
      BusinessConcepts.get_business_concept_version!(business_concept_version_id)

    case Search.list_business_concept_versions(business_concept_version.business_concept_id, user) do
      %{results: business_concept_versions} ->
        render(
          conn,
          "versions.json",
          business_concept_versions: business_concept_versions,
          hypermedia: hypermedia("business_concept_version", conn, business_concept_versions)
        )

      _ ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ErrorView, :"422.json")
    end
  end

  swagger_path :show do
    description("Show Business Concept Version")
    produces("application/json")

    parameters do
      id(:path, :integer, "Business Concept ID", required: true)
    end

    response(200, "OK", Schema.ref(:BusinessConceptVersionResponse))
    response(400, "Client Error")
  end

  def show(conn, %{"id" => id}) do
    user = conn.assigns[:current_user]
    business_concept_version = BusinessConcepts.get_business_concept_version!(id)

    with true <- can?(user, view_business_concept(business_concept_version)) do
      template = TemplateSupport.get_preprocessed_template(business_concept_version, user)

      business_concept_version =
        business_concept_version
        |> Repo.preload([business_concept: [:parent, :children]])
        |> add_completeness_to_bc_version(template)

      render(
        conn,
        "show.json",
        business_concept_version: business_concept_version,
        hypermedia: hypermedia("business_concept_version", conn, business_concept_version),
        template: template
      )
    else
      false ->
        conn
        |> put_status(:forbidden)
        |> render(ErrorView, :"403.json")

      _error ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ErrorView, :"422.json")
    end
  end

  swagger_path :delete do
    description("Delete a business concept version")
    produces("application/json")

    parameters do
      id(:path, :integer, "Business Concept Version ID", required: true)
    end

    response(204, "No Content")
    response(400, "Client Error")
  end

  def delete(conn, %{"id" => id}) do
    user = conn.assigns[:current_user]
    business_concept_version = BusinessConcepts.get_business_concept_version!(id)
    business_concept_id = business_concept_version.business_concept.id

    with true <- can?(user, delete(business_concept_version)),
         {:ok, %BusinessConceptVersion{}} <-
           BusinessConcepts.delete_business_concept_version(business_concept_version) do
      audit_payload =
        business_concept_version
        |> Map.take([:version])

      audit = %{
        "audit" => %{
          "resource_id" => business_concept_id,
          "resource_type" => "business_concept",
          "payload" => audit_payload
        }
      }

      Audit.create_event(conn, audit, @events.delete_concept_draft)

      send_resp(conn, :no_content, "")
    else
      false ->
        conn
        |> put_status(:forbidden)
        |> render(ErrorView, :"403.json")

      _error ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ErrorView, :"422.json")
    end
  end

  swagger_path :send_for_approval do
    description("Submit a draft business concept for approval")
    produces("application/json")

    parameters do
      id(:path, :integer, "Business Concept Version ID", required: true)
    end

    response(200, "OK", Schema.ref(:BusinessConceptResponse))
    response(403, "User is not authorized to perform this action")
    response(422, "Business concept invalid state")
  end

  def send_for_approval(conn, %{"business_concept_version_id" => id}) do
    user = conn.assigns[:current_user]
    business_concept_version = BusinessConcepts.get_business_concept_version!(id)
    draft = BusinessConcept.status().draft

    case {business_concept_version.status, business_concept_version.current} do
      {^draft, true} ->
        send_for_approval(conn, user, business_concept_version)

      _ ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ErrorView, :"422.json")
    end
  end

  swagger_path :publish do
    description("Publish a business concept which is pending approval")
    produces("application/json")

    parameters do
      id(:path, :integer, "Business Concept Version ID", required: true)
    end

    response(200, "OK", Schema.ref(:BusinessConceptResponse))
    response(403, "User is not authorized to perform this action")
    response(422, "Business concept invalid state")
  end

  def publish(conn, %{"business_concept_version_id" => id}) do
    user = conn.assigns[:current_user]
    business_concept_version = BusinessConcepts.get_business_concept_version!(id)
    pending_approval = BusinessConcept.status().pending_approval

    case {business_concept_version.status, business_concept_version.current} do
      {^pending_approval, true} ->
        publish(conn, user, business_concept_version)

      _ ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ErrorView, :"422.json")
    end
  end

  swagger_path :reject do
    description("Reject a business concept which is pending approval")
    produces("application/json")

    parameters do
      id(:path, :integer, "Business Concept Version ID", required: true)
      reject_reason(:body, :string, "Rejection reason")
    end

    response(200, "OK", Schema.ref(:BusinessConceptResponse))
    response(403, "User is not authorized to perform this action")
    response(422, "Business concept invalid state")
  end

  def reject(conn, %{"business_concept_version_id" => id} = params) do
    user = conn.assigns[:current_user]
    business_concept_version = BusinessConcepts.get_business_concept_version!(id)
    pending_approval = BusinessConcept.status().pending_approval

    case {business_concept_version.status, business_concept_version.current} do
      {^pending_approval, true} ->
        reject(conn, user, business_concept_version, Map.get(params, "reject_reason"))

      _ ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ErrorView, :"422.json")
    end
  end

  swagger_path :undo_rejection do
    description("Create a draft from a rejected business concept")
    produces("application/json")

    parameters do
      id(:path, :integer, "Business Concept Version ID", required: true)
    end

    response(200, "OK", Schema.ref(:BusinessConceptResponse))
    response(403, "User is not authorized to perform this action")
    response(422, "Business concept invalid state")
  end

  def undo_rejection(conn, %{"business_concept_version_id" => id}) do
    user = conn.assigns[:current_user]
    business_concept_version = BusinessConcepts.get_business_concept_version!(id)
    rejected = BusinessConcept.status().rejected

    case {business_concept_version.status, business_concept_version.current} do
      {^rejected, true} ->
        undo_rejection(conn, user, business_concept_version)

      _ ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ErrorView, :"422.json")
    end
  end

  swagger_path :version do
    description("Create a new draft from a published business concept")
    produces("application/json")

    parameters do
      id(:path, :integer, "Business Concept Version ID", required: true)
    end

    response(200, "OK", Schema.ref(:BusinessConceptResponse))
    response(403, "User is not authorized to perform this action")
    response(422, "Business concept invalid state")
  end

  def version(conn, %{"business_concept_version_id" => id}) do
    user = conn.assigns[:current_user]
    business_concept_version = BusinessConcepts.get_business_concept_version!(id)
    published = BusinessConcept.status().published

    case {business_concept_version.status, business_concept_version.current} do
      {^published, true} ->
        do_version(conn, user, business_concept_version)

      _ ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ErrorView, :"422.json")
    end
  end

  swagger_path :deprecate do
    description("Deprecate a published business concept")
    produces("application/json")

    parameters do
      id(:path, :integer, "Business Concept Version ID", required: true)
    end

    response(200, "OK", Schema.ref(:BusinessConceptResponse))
    response(403, "User is not authorized to perform this action")
    response(422, "Business concept invalid state")
  end

  def deprecate(conn, %{"business_concept_version_id" => id}) do
    user = conn.assigns[:current_user]
    business_concept_version = BusinessConcepts.get_business_concept_version!(id)
    published = BusinessConcept.status().published

    case {business_concept_version.status, business_concept_version.current} do
      {^published, true} ->
        deprecate(conn, user, business_concept_version)

      _ ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ErrorView, :"422.json")
    end
  end

  defp add_completeness_to_bc_version(business_concept_version, template) do
    bc_completeness =
      business_concept_version
      |> Map.get(:content)
      |> calculate_completeness(
        template
        |> Map.fetch!(:content)
        |> Enum.filter(&(!Map.get(&1, "required", false)))
      )

    Map.put(business_concept_version, :completeness, bc_completeness)
  end

  defp calculate_completeness(_, []), do: 100.00

  defp calculate_completeness(%{} = business_concept_content, _)
       when business_concept_content == %{},
       do: 0.00

  defp calculate_completeness(business_concept_content, template_optional_fields) do
    valid_keys_length =
      business_concept_content
      |> Map.keys()
      |> Enum.filter(&verify_value_type(Map.fetch!(business_concept_content, &1)))
      |> Enum.filter(
        &Enum.any?(template_optional_fields, fn x -> Map.fetch!(x, "name") == &1 end)
      )
      |> length()

    Float.round(valid_keys_length / length(template_optional_fields) * 100, 2)
  end

  defp verify_value_type([]), do: false
  defp verify_value_type(%{} = value) when value == %{}, do: false
  defp verify_value_type(value) when is_binary(value), do: String.length(String.trim(value)) !== 0
  # Otherwise, we will assume that the type is correct for now
  defp verify_value_type(_), do: true

  defp send_for_approval(conn, user, business_concept_version) do
    update_status(
      conn,
      user,
      business_concept_version,
      BusinessConcept.status().pending_approval,
      @events.concept_sent_for_approval,
      can?(user, send_for_approval(business_concept_version))
    )
  end

  defp undo_rejection(conn, user, business_concept_version) do
    update_status(
      conn,
      user,
      business_concept_version,
      BusinessConcept.status().draft,
      @events.concept_rejection_canceled,
      can?(user, undo_rejection(business_concept_version))
    )
  end

  defp publish(conn, user, business_concept_version) do
    business_concept_id = business_concept_version.business_concept.id

    with true <- can?(user, publish(business_concept_version)),
         {:ok, %{published: %BusinessConceptVersion{} = concept}} <-
           BusinessConcepts.publish_business_concept_version(business_concept_version) do
      audit = %{
        "audit" => %{
          "resource_id" => business_concept_id,
          "resource_type" => "business_concept",
          "payload" => %{}
        }
      }

      Audit.create_event(conn, audit, @events.concept_published)

      render(
        conn,
        "show.json",
        business_concept_version: concept,
        hypermedia: hypermedia("business_concept_version", conn, concept),
        template: TemplateSupport.get_template(business_concept_version)
      )
    else
      false ->
        conn
        |> put_status(:forbidden)
        |> render(ErrorView, :"403.json")

      _error ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ErrorView, :"422.json")
    end
  end

  defp reject(conn, user, business_concept_version, reason) do
    attrs = %{reject_reason: reason}

    with true <- can?(user, reject(business_concept_version)),
         {:ok, %BusinessConceptVersion{} = version} <-
           BusinessConcepts.reject_business_concept_version(business_concept_version, attrs) do
      business_concept_id = version.business_concept.id

      audit = %{
        "audit" => %{
          "resource_id" => business_concept_id,
          "resource_type" => "business_concept",
          "payload" => %{}
        }
      }

      Audit.create_event(conn, audit, @events.concept_rejected)

      render(
        conn,
        "show.json",
        business_concept_version: version,
        hypermedia: hypermedia("business_concept_version", conn, version),
        template: TemplateSupport.get_preprocessed_template(business_concept_version, user)
      )
    else
      false ->
        conn
        |> put_status(:forbidden)
        |> render(ErrorView, :"403.json")

      _error ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ErrorView, :"422.json")
    end
  end

  defp deprecate(conn, user, business_concept_version) do
    update_status(
      conn,
      user,
      business_concept_version,
      BusinessConcept.status().deprecated,
      @events.concept_deprecated,
      can?(user, deprecate(business_concept_version))
    )
  end

  defp update_status(conn, user, business_concept_version, status, event, authorized) do
    attrs = %{status: status}
    business_concept_id = business_concept_version.business_concept.id

    with true <- authorized,
         {:ok, %BusinessConceptVersion{} = concept} <-
           BusinessConcepts.update_business_concept_version_status(
             business_concept_version,
             attrs
           ) do
      audit = %{
        "audit" => %{
          "resource_id" => business_concept_id,
          "resource_type" => "business_concept",
          "payload" => %{}
        }
      }

      Audit.create_event(conn, audit, event)

      render(
        conn,
        "show.json",
        business_concept_version: concept,
        hypermedia: hypermedia("business_concept_version", conn, concept),
        template: TemplateSupport.get_preprocessed_template(concept, user)
      )
    else
      false ->
        conn
        |> put_status(:forbidden)
        |> render(ErrorView, :"403.json")

      _error ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ErrorView, :"422.json")
    end
  end

  defp do_version(conn, user, business_concept_version) do
    business_concept_id = business_concept_version.business_concept.id

    with true <- can?(user, version(business_concept_version)),
         {:ok, %{current: %BusinessConceptVersion{} = new_version}} <-
           BusinessConcepts.version_business_concept(user, business_concept_version) do
      audit_payload =
        new_version
        |> Map.take([:version])

      audit = %{
        "audit" => %{
          "resource_id" => business_concept_id,
          "resource_type" => "business_concept",
          "payload" => audit_payload
        }
      }

      Audit.create_event(conn, audit, @events.new_concept_draft)

      conn
      |> put_status(:created)
      |> render(
        "show.json",
        business_concept_version: new_version,
        hypermedia: hypermedia("business_concept_version", conn, new_version),
        template: TemplateSupport.get_template(new_version)
      )
    else
      false ->
        conn
        |> put_status(:forbidden)
        |> render(ErrorView, :"403.json")

      _error ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ErrorView, :"422.json")
    end
  end

  swagger_path :update do
    description("Updates Business Concept Version")
    produces("application/json")

    parameters do
      business_concept_version(
        :body,
        Schema.ref(:BusinessConceptVersionUpdate),
        "Business Concept Version update attrs"
      )

      id(:path, :integer, "Business Concept Version ID", required: true)
    end

    response(200, "OK", Schema.ref(:BusinessConceptVersionResponse))
    response(400, "Client Error")
  end

  def update(conn, %{"id" => id, "business_concept_version" => business_concept_version_params}) do
    user = conn.assigns[:current_user]

    business_concept_version = BusinessConcepts.get_business_concept_version!(id)
    business_concept_id = business_concept_version.business_concept.id
    concept_name = Map.get(business_concept_version_params, "name")
    template = TemplateSupport.get_template(business_concept_version)
    content_schema = Map.get(template, :content)

    parent_id = Map.get(business_concept_version_params, "parent_id", nil)

    business_concept_attrs =
      %{}
      |> Map.put("parent_id", parent_id)
      |> Map.put("last_change_by", user.id)
      |> Map.put("last_change_at", DateTime.utc_now())

    update_params =
      business_concept_version_params
      |> Map.put("business_concept", business_concept_attrs)
      |> Map.put("content_schema", content_schema)
      |> Map.update("content", %{}, & &1)
      |> Map.update("related_to", [], & &1)
      |> Map.put("last_change_by", user.id)
      |> Map.put("last_change_at", DateTime.utc_now())

    related_to = Map.get(update_params, "related_to")

    with true <- can?(user, update(business_concept_version)),
         {:name_available} <-
           BusinessConcepts.check_business_concept_name_availability(
             template.name,
             concept_name,
             business_concept_version.business_concept.id
           ),
         {:valid_related_to} <-
           BusinessConcepts.check_valid_related_to(template.name, related_to),
         {:ok, %BusinessConceptVersion{} = concept_version} <-
           BusinessConcepts.update_business_concept_version(
             business_concept_version,
             update_params
           ) do
      audit_payload = get_changed_params(business_concept_version, concept_version)

      audit = %{
        "audit" => %{
          "resource_id" => business_concept_id,
          "resource_type" => "business_concept",
          "payload" => audit_payload
        }
      }

      Audit.create_event(conn, audit, @events.update_concept_draft)

      render(
        conn,
        "show.json",
        business_concept_version: concept_version,
        hypermedia: hypermedia("business_concept_version", conn, concept_version),
        template: template
      )
    else
      false ->
        conn
        |> put_status(:forbidden)
        |> render(ErrorView, :"403.json")

      {:name_not_available} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: %{name: ["bc_version unique"]}})

      {:not_valid_related_to} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: %{related_to: ["bc_version invalid"]}})

      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(TdBgWeb.ChangesetView, "error.json", changeset: changeset)

      _error ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ErrorView, :"422.json")
    end
  end

  defp get_changed_params(
         %BusinessConceptVersion{} = old,
         %BusinessConceptVersion{} = new
       ) do
    fields_to_compare = [:name, :description]

    diffs =
      Enum.reduce(fields_to_compare, %{}, fn field, acc ->
        oldval = Map.get(old, field)
        newval = Map.get(new, field)

        case oldval == newval do
          true -> acc
          false -> Map.put(acc, field, newval)
        end
      end)

    oldcontent = Map.get(old, :content)
    newcontent = Map.get(new, :content)

    added_keys = Map.keys(newcontent) -- Map.keys(oldcontent)

    added =
      Enum.reduce(added_keys, %{}, fn key, acc ->
        Map.put(acc, key, Map.get(newcontent, key))
      end)

    removed_keys = Map.keys(oldcontent) -- Map.keys(newcontent)

    removed =
      Enum.reduce(removed_keys, %{}, fn key, acc ->
        Map.put(acc, key, Map.get(oldcontent, key))
      end)

    changed_keys = Map.keys(newcontent) -- removed_keys -- added_keys

    changed =
      Enum.reduce(changed_keys, %{}, fn key, acc ->
        oldval = Map.get(oldcontent, key)
        newval = Map.get(newcontent, key)

        case oldval == newval do
          true -> acc
          false -> Map.put(acc, key, newval)
        end
      end)

    changed_content =
      %{}
      |> Map.put(:added, added)
      |> Map.put(:removed, removed)
      |> Map.put(:changed, changed)

    diffs
    |> Map.put(:content, changed_content)
  end

  swagger_path :get_data_structures do
    description("Get business concept version associated data structures")
    produces("application/json")

    parameters do
      id(:path, :integer, "Business Concept Version ID", required: true)
    end

    response(200, "OK", Schema.ref(:DataStructuresResponse))
    response(400, "Client Error")
  end

  def get_data_structures(conn, %{"business_concept_version_id" => id}) do
    user = conn.assigns[:current_user]
    business_concept_version = BusinessConcepts.get_business_concept_version!(id)

    with true <- can?(user, get_data_structures(business_concept_version)) do
      ous = BusinessConceptSupport.get_concept_ous(business_concept_version, user)
      Logger.info("Retrieved ous #{inspect(ous)}")
      data_structures = @td_dd_api.get_data_structures(%{ou: Enum.join(ous, "§")})
      cooked_data_structures = cooked_data_structures(data_structures)

      render(
        conn,
        DataStructureView,
        "data_structures.json",
        data_structures: cooked_data_structures
      )
    else
      false ->
        conn
        |> put_status(:forbidden)
        |> render(ErrorView, :"403.json")

      error ->
        Logger.error("While getting data structures... #{inspect(error)}")

        conn
        |> put_status(:unprocessable_entity)
        |> render(ErrorView, :"422.json")
    end
  end

  swagger_path :get_data_fields do
    description("Get business concept version associated data structure data fields")
    produces("application/json")

    parameters do
      business_concept_id(:path, :integer, "Business Concept Version ID", required: true)
      data_structure_id(:path, :integer, "Business Concept Version ID", required: true)
    end

    response(200, "OK", Schema.ref(:ConceptFieldsResponse))
    response(400, "Client Error")
  end

  def get_data_fields(conn, %{
        "business_concept_version_id" => id,
        "data_structure_id" => data_structure_id
      }) do
    user = conn.assigns[:current_user]
    business_concept_version = BusinessConcepts.get_business_concept_version!(id)

    with true <- can?(user, get_data_fields(business_concept_version)) do
      ous = BusinessConceptSupport.get_concept_ous(business_concept_version, user)
      data_structure = @td_dd_api.get_data_fields(%{data_structure_id: data_structure_id})

      data_fields =
        case Enum.member?(ous, data_structure["ou"]) do
          true -> Map.get(data_structure, "data_fields")
          _ -> []
        end

      cooked_data_fields = cooked_data_fields(data_fields)
      render(conn, DataFieldView, "data_fields.json", data_fields: cooked_data_fields)
    else
      false ->
        conn
        |> put_status(:forbidden)
        |> render(ErrorView, :"403.json")

      error ->
        Logger.error("While getting data structures... #{inspect(error)}")

        conn
        |> put_status(:unprocessable_entity)
        |> render(ErrorView, :"422.json")
    end
  end

  defp cooked_data_structures(data_structures) do
    data_structures
    |> Enum.map(&CollectionUtils.atomize_keys(&1))
    |> Enum.map(&Map.take(&1, [:id, :ou, :system, :group, :name]))
  end

  defp cooked_data_fields(data_fields) do
    data_fields
    |> Enum.map(&CollectionUtils.atomize_keys(&1))
    |> Enum.map(&Map.take(&1, [:id, :name]))
  end
end
