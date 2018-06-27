defmodule TdBgWeb.BusinessConceptVersionController do
  require Logger
  use TdBgWeb, :controller
  use TdBg.Hypermedia, :controller
  use PhoenixSwagger

  import Canada, only: [can?: 2]

  alias TdBg.Audit
  alias TdBg.BusinessConcept.Download
  alias TdBg.BusinessConcept.Search
  alias TdBg.BusinessConcepts
  alias TdBg.BusinessConcepts.BusinessConcept
  alias TdBg.BusinessConcepts.BusinessConceptVersion
  alias TdBg.ConceptFields
  alias TdBg.Permissions
  alias TdBg.Taxonomies
  alias TdBg.Templates
  alias TdBg.Utils.CollectionUtils
  alias TdBgWeb.BusinessConceptSupport
  alias TdBgWeb.BusinessConceptSupport
  alias TdBgWeb.ConceptFieldView
  alias TdBgWeb.DataFieldView
  alias TdBgWeb.DataStructureView
  alias TdBgWeb.ErrorView
  alias TdBgWeb.SwaggerDefinitions

  @td_dd_api   Application.get_env(:td_bg, :dd_service)[:api_service]
  @td_auth_api Application.get_env(:td_bg, :auth_service)[:api_service]

  @events %{add_concept_field: "add_concept_field", delete_concept_field: "delete_concept_field"}

  action_fallback(TdBgWeb.FallbackController)

  def swagger_definitions do
    SwaggerDefinitions.business_concept_version_definitions()
  end

  swagger_path :index do
    get("/business_concept_versions")
    description("Business Concept Versions")

    parameters do
      search(
        :body, Schema.ref(:BusinessConceptVersionFilterRequest), "Search query and filter parameters"
      )
    end

    response(200, "OK", Schema.ref(:BusinessConceptVersionsResponse))
  end

  def index(conn, params) do
    user = conn.assigns[:current_user]
    business_concept_versions = Search.search_business_concept_versions(params, user)

    render(
      conn,
      "list.json",
      business_concept_versions: business_concept_versions,
      hypermedia:
        collection_hypermedia(
          "business_concept_version",
          conn,
          business_concept_versions,
          BusinessConceptVersion
        )
    )
  end

  swagger_path :search do
    post("/business_concept_versions/search")
    description("Business Concept Versions")

    parameters do
      search(
        :body, Schema.ref(:BusinessConceptVersionFilterRequest), "Search query and filter parameters"
      )
    end

    response(200, "OK", Schema.ref(:BusinessConceptVersionsResponse))
  end

  def search(conn, params) do
    user = conn.assigns[:current_user]
    business_concept_versions = Search.search_business_concept_versions(params, user)

    render(
      conn,
      "list.json",
      business_concept_versions: business_concept_versions,
      hypermedia:
        collection_hypermedia(
          "business_concept_version",
          conn,
          business_concept_versions,
          BusinessConceptVersion
        )
    )
  end

  def csv(conn, params) do
    user = conn.assigns[:current_user]
    concepts = Search.search_business_concept_versions(params, user, 0, 10_000)
    conn
      |> put_resp_content_type("text/csv", "utf-8")
      |> put_resp_header("content-disposition", "attachment; filename=\"concepts.zip\"")
      |> send_resp(200, Download.to_csv(concepts))
  end

  swagger_path :create do
    post("/business_concept_versions")
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
    %{:content => content_schema} = Templates.get_template_by_name(concept_type)

    concept_name = Map.get(business_concept_params, "name")

    domain_id = Map.get(business_concept_params, "domain_id")
    domain = Taxonomies.get_domain!(domain_id)

    business_concept_attrs =
      %{}
      |> Map.put("domain_id", domain_id)
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
         {:ok, %BusinessConceptVersion{} = concept} <-
           BusinessConcepts.create_business_concept(creation_attrs) do
      conn =
        conn
        |> put_status(:created)
        |> put_resp_header(
          "location",
          business_concept_path(conn, :show, concept.business_concept)
        )
        |> render("show.json", business_concept_version: concept)

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
    get("/business_concepts/{business_concept_id}/versions")
    description("List Business Concept Versions")

    parameters do
      business_concept_id(:path, :integer, "Business Concept ID", required: true)
    end

    response(200, "OK", Schema.ref(:BusinessConceptVersionsResponse))
  end

  def versions(conn, %{"business_concept_id" => business_concept_id}) do
    user = conn.assigns[:current_user]

    business_concept_version =
      BusinessConcepts.get_business_concept_version!(business_concept_id)

    business_concept = business_concept_version.business_concept

    with true <- can?(user, view_versions(business_concept_version)) do
      allowed_status = get_allowed_version_status_by_role(user, business_concept)

      business_concept_versions =
        BusinessConcepts.list_business_concept_versions(business_concept.id, allowed_status)

      user_ids = business_concept_versions
      |> Enum.reduce([], &([Map.get(&1, :last_change_by)|&2]))
      |> Enum.uniq

      users = @td_auth_api.search_users(%{"ids" => user_ids})

      render(
        conn,
        "index.json",
        business_concept_versions: business_concept_versions,
        hypermedia: hypermedia("business_concept_version", conn, business_concept_versions),
        users: users
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

  defp get_allowed_version_status_by_role(user, business_concept) do
    case user.is_admin do
      true ->
        BusinessConcept.status_values()

      false ->
        permissions_to_status = BusinessConcept.permissions_to_status()

        %{user_id: user.id, domain_id: business_concept.domain_id}
        |> Permissions.get_permissions_in_resource()
        |> Enum.reduce([], fn permission, acc ->
          acc ++ get_from_permissions(permissions_to_status, permission)
        end)
    end
  end

  defp get_from_permissions(permissions_to_status, permission) do
    case Map.get(permissions_to_status, permission) do
      nil -> []
      status -> [status]
    end
  end

  swagger_path :show do
    get("/business_concept_versions/{id}")
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
      render(
        conn,
        "show.json",
        business_concept_version: business_concept_version,
        hypermedia: hypermedia("business_concept_version", conn, business_concept_version)
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
    delete("/business_concept_versions/{id}")
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

    with true <- can?(user, delete(business_concept_version)),
         {:ok, %BusinessConceptVersion{}} <-
           BusinessConcepts.delete_business_concept_version(business_concept_version) do
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
    post("/business_concept_versions/{id}/send_for_approval")
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
    post("/business_concept_versions/{id}/publish")
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
    post("/business_concept_versions/{id}/reject")
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
    post("/business_concept_versions/{id}/undo_rejection")
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
    post("/business_concept_versions/{id}/version")
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
    post("/business_concept_versions/{id}/deprecate")
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

  defp send_for_approval(conn, user, business_concept_version) do
    update_status(
      conn,
      business_concept_version,
      BusinessConcept.status().pending_approval,
      can?(user, send_for_approval(business_concept_version))
    )
  end

  defp undo_rejection(conn, user, business_concept_version) do
    update_status(
      conn,
      business_concept_version,
      BusinessConcept.status().draft,
      can?(user, undo_rejection(business_concept_version))
    )
  end

  defp publish(conn, user, business_concept_version) do
    with true <- can?(user, publish(business_concept_version)),
         {:ok, %{published: %BusinessConceptVersion{} = concept}} <-
           BusinessConcepts.publish_business_concept_version(business_concept_version) do
      render(
        conn,
        "show.json",
        business_concept_version: concept,
        hypermedia: hypermedia("business_concept_version", conn, concept)
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
         {:ok, %BusinessConceptVersion{} = concept} <-
           BusinessConcepts.reject_business_concept_version(business_concept_version, attrs) do
      render(
        conn,
        "show.json",
        business_concept_version: concept,
        hypermedia: hypermedia("business_concept_version", conn, concept)
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
      business_concept_version,
      BusinessConcept.status().deprecated,
      can?(user, deprecate(business_concept_version))
    )
  end

  defp update_status(conn, business_concept_version, status, authorized) do
    attrs = %{status: status}

    with true <- authorized,
         {:ok, %BusinessConceptVersion{} = concept} <-
           BusinessConcepts.update_business_concept_version_status(
             business_concept_version,
             attrs
           ) do
      render(
        conn,
        "show.json",
        business_concept_version: concept,
        hypermedia: hypermedia("business_concept_version", conn, concept)
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
    with true <- can?(user, version(business_concept_version)),
         {:ok, %{current: %BusinessConceptVersion{} = new_version}} <-
           BusinessConcepts.version_business_concept(user, business_concept_version) do
      conn
      |> put_status(:created)
      |> render(
        "show.json",
        business_concept_version: new_version,
        hypermedia: hypermedia("business_concept_version", conn, new_version)
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
    put("/business_concept_versions/{id}")
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
    concept_type = business_concept_version.business_concept.type
    concept_name = Map.get(business_concept_version_params, "name")
    %{:content => content_schema} = Templates.get_template_by_name(concept_type)

    business_concept_attrs =
      %{}
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
             concept_type,
             concept_name,
             business_concept_version.business_concept.id
           ),
         {:valid_related_to} <- BusinessConcepts.check_valid_related_to(concept_type, related_to),
         {:ok, %BusinessConceptVersion{} = concept_version} <-
           BusinessConcepts.update_business_concept_version(
             business_concept_version,
             update_params
           ) do
      render(
        conn,
        "show.json",
        business_concept_version: concept_version,
        hypermedia: hypermedia("business_concept_version", conn, concept_version)
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

  swagger_path :get_fields do
    get("/business_concept_versions/{business_concept_version_id}/fields")
    description("Get business concept version data fields")
    produces("application/json")

    parameters do
      business_concept_version_id(:path, :integer, "Business Concept Version ID", required: true)
    end

    response(200, "OK", Schema.ref(:ConceptFieldsResponse))
    response(400, "Client Error")
  end

  def get_fields(conn, %{"business_concept_version_id" => id}) do
    user = conn.assigns[:current_user]
    business_concept_version = BusinessConcepts.get_business_concept_version!(id)

    with true <- can?(user, get_fields(business_concept_version)) do
      concept_fields =
        ConceptFields.list_concept_fields(inspect(business_concept_version.business_concept_id))

      render(conn, ConceptFieldView, "concept_fields.json", concept_fields: concept_fields)
    else
      false ->
        conn
        |> put_status(:forbidden)
        |> render(ErrorView, :"403.json")

      error ->
        Logger.error("While getting concept fields... #{inspect(error)}")

        conn
        |> put_status(:unprocessable_entity)
        |> render(ErrorView, :"422.json")
    end
  end

  swagger_path :get_field do
    get("/business_concept_versions/{business_concept_id}/fields/{concept_field_id}")
    description("Get business concept version field")
    produces("application/json")

    parameters do
      business_concept_id(:path, :integer, "Business Concept Version ID", required: true)
      concept_field_id(:path, :integer, "Concept Field ID", required: true)
    end

    response(200, "OK", Schema.ref(:ConceptFieldsResponse))
    response(400, "Client Error")
  end

  def get_field(conn, %{
        "business_concept_version_id" => id,
        "concept_field_id" => concept_field_id
      }) do
    user = conn.assigns[:current_user]
    business_concept_version = BusinessConcepts.get_business_concept_version!(id)

    with true <- can?(user, get_field(business_concept_version)) do
      concept_field = ConceptFields.get_concept_field!(concept_field_id)
      render(conn, ConceptFieldView, "concept_field.json", concept_field: concept_field)
    else
      false ->
        conn
        |> put_status(:forbidden)
        |> render(ErrorView, :"403.json")

      error ->
        Logger.error("While getting concept field... #{inspect(error)}")

        conn
        |> put_status(:unprocessable_entity)
        |> render(ErrorView, :"422.json")
    end
  end

  swagger_path :add_field do
    post("/business_concept_versions/{business_concept_version_id}/fields")
    description("Updates Business Concept Version Field")
    produces("application/json")

    parameters do
      field(:body, Schema.ref(:AddField), "Concept field")
      business_concept_version_id(:path, :integer, "Business Concept Version ID", required: true)
    end

    response(200, "OK", Schema.ref(:ConceptFieldResponse))
    response(400, "Client Error")
  end

  def add_field(conn, %{"business_concept_version_id" => id, "field" => field} = params) do
    user = conn.assigns[:current_user]
    business_concept_version = BusinessConcepts.get_business_concept_version!(id)
    business_concept_id = business_concept_version.business_concept_id

    create_attrs = %{concept: inspect(business_concept_id), field: field}

    with true <- can?(user, add_field(business_concept_version)),
         {:ok, concept_field} <- ConceptFields.create_concept_field(create_attrs) do
      audit = %{
        "audit" => %{
          "resource_id" => id,
          "resource_type" => "business_concept_version",
          "payload" => params
        }
      }

      Audit.create_event(conn, audit, @events.add_concept_field)

      render(conn, ConceptFieldView, "concept_field.json", concept_field: concept_field)
    else
      false ->
        conn
        |> put_status(:forbidden)
        |> render(ErrorView, :"403.json")

      error ->
        Logger.error("While adding  concept fields... #{inspect(error)}")

        conn
        |> put_status(:unprocessable_entity)
        |> render(ErrorView, :"422.json")
    end
  end

  swagger_path :delete_field do
    delete("/business_concept_versions/{business_concept_version_id}/fields/{concept_field_id}")
    description("Deletes Business Concept Version Field")
    produces("application/json")

    parameters do
      business_concept_version_id(:path, :integer, "Business Concept Version ID", required: true)
      concept_field_id(:path, :integer, "Field ID", required: true)
    end

    response(204, "No Content")
    response(400, "Client Error")
  end

  def delete_field(
        conn,
        %{"business_concept_version_id" => id, "concept_field_id" => concept_field_id} = params
      ) do
    user = conn.assigns[:current_user]
    business_concept_version = BusinessConcepts.get_business_concept_version!(id)
    concept_field = ConceptFields.get_concept_field!(concept_field_id)

    with true <- can?(user, delete_field(business_concept_version)) do
      ConceptFields.delete_concept_field(concept_field)

      audit = %{
        "audit" => %{
          "resource_id" => id,
          "resource_type" => "business_concept_version",
          "payload" => params
        }
      }

      Audit.create_event(conn, audit, @events.delete_concept_field)

      send_resp(conn, :no_content, "")
    else
      false ->
        conn
        |> put_status(:forbidden)
        |> render(ErrorView, :"403.json")

      error ->
        Logger.error("While deleting concept field... #{inspect(error)}")

        conn
        |> put_status(:unprocessable_entity)
        |> render(ErrorView, :"422.json")
    end
  end

  swagger_path :get_data_structures do
    get("/business_concept_versions/{id}/data_structures")
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
    get(
      "/business_concept_versions/{business_concept_id}/data_structures/{data_structure_id}/data_fields"
    )

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
