defmodule TdBgWeb.BusinessConceptVersionController do
  use TdBgWeb, :controller
  use PhoenixSwagger

  import Canada, only: [can?: 2]

  alias TdBg.BusinessConcepts
  alias TdBg.BusinessConcepts.BusinessConcept
  alias TdBg.BusinessConcepts.BusinessConceptVersion
  alias Poison, as: JSON
  alias TdBgWeb.ErrorView
  alias TdBgWeb.SwaggerDefinitions
  alias TdBg.Permissions
  alias TdBg.Permissions.Role

  action_fallback TdBgWeb.FallbackController

  def swagger_definitions do
    SwaggerDefinitions.business_concept_version_definitions()
  end

  swagger_path :index do
    get "/business_concept_versions"
    description "List Business Concept Versions"
    response 200, "OK", Schema.ref(:BusinessConceptVersionResponse)
  end

  def index(conn, _params) do
    business_concept_versions = BusinessConcepts.list_all_business_concept_versions()
    render(conn, "index.json", business_concept_versions: business_concept_versions)
  end

  swagger_path :versions do
    get "/business_concepts/{business_concept_id}/versions"
    description "List Business Concept Versions"
    parameters do
      id :path, :integer, "Business Concept ID", required: true
    end
    response 200, "OK", Schema.ref(:BusinessConceptVersionsResponse)
  end

  def versions(conn, %{"business_concept_id" => business_concept_id}) do
    business_concept_version = BusinessConcepts.get_current_version_by_business_concept_id!(business_concept_id)
    business_concept = business_concept_version.business_concept

    user = conn.assigns.current_user

    with true <- can?(user, view_versions(business_concept_version)) do
      allowed_status = get_allowed_version_status_by_role(user, business_concept)
      business_concept_versions = BusinessConcepts.list_business_concept_versions(business_concept.id, allowed_status)
      render(conn, "index.json", business_concept_versions: business_concept_versions)
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
    if user.is_admin do
      BusinessConcept.get_allowed_version_status_by_role(Role.admin)
    else
      role_name = %{user_id: user.id, data_domain_id:  business_concept.data_domain_id}
      role_name
      |> Permissions.get_role_in_resource
      |> Map.get(:name)
      |> String.to_atom
      |> BusinessConcept.get_allowed_version_status_by_role
    end
  end

  swagger_path :create do
    post "/business_concept_versions"
    description "Creates a Business Concept Version"
    produces "application/json"
    parameters do
      business_concept :body, Schema.ref(:BusinessConceptVersionCreate), "Business Concept Version create attrs"
    end
    response 200, "Created", Schema.ref(:BusinessConceptVersionResponse)
    response 400, "Client Error"
  end

  def create(conn, %{"business_concept_id" => business_concept_id, "business_concept" => business_concept_params}) do
    business_concept_version = BusinessConcepts.get_current_version_by_business_concept_id!(business_concept_id)
    business_concept = business_concept_version.business_concept
    concept_type = business_concept.type
    concept_name = Map.get(business_concept_params, "name")
    content_schema = get_content_schema(concept_type)

    user = conn.assigns.current_user

    business_concept = business_concept
    |> Map.put("last_change_by", user.id)
    |> Map.put("last_change_at", DateTime.utc_now())

    draft_attrs = Map.from_struct(business_concept_version)
    draft_attrs = draft_attrs
    |> Map.merge(business_concept_params)
    |> Map.put("business_concept", business_concept)
    |> Map.put("content_schema", content_schema)
    |> Map.put("last_change_by", user.id)
    |> Map.put("last_change_at", DateTime.utc_now())
    |> Map.put("mod_comments", business_concept_params["mod_comments"])
    |> Map.put("status", BusinessConcept.status.draft)
    |> Map.put("version", business_concept_version.version + 1)

    with true <- can?(user, update_published(business_concept_version)),
         {:ok, 0} <- BusinessConcepts.exist_business_concept_by_type_and_name?(concept_type, concept_name, business_concept_id),
         {:ok, %BusinessConceptVersion{} = new_version} <- BusinessConcepts.create_business_concept_version(draft_attrs) do
      conn
        |> put_status(:created)
        |> put_resp_header("location", business_concept_version_path(conn, :show, business_concept_version))
        |> render("show.json", business_concept_version: new_version)
    else
      false ->
        conn
        |> put_status(:forbidden)
        |> render(ErrorView, :"403.json")
      __error ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ErrorView, :"422.json")
    end
  end

  swagger_path :show do
    get "/business_concept_version/{id}"
    description "Show Business Concept Version"
    produces "application/json"
    parameters do
      id :path, :integer, "Business Concept ID", required: true
    end
    response 200, "OK", Schema.ref(:BusinessConceptVersionResponse)
    response 400, "Client Error"
  end

  def show(conn, %{"id" => id}) do
    business_concept_version = BusinessConcepts.get_business_concept_version!(id)
    render(conn, "show.json", business_concept_version: business_concept_version)
  end

  defp get_content_schema(content_type) do
    filename = Application.get_env(:td_bg, :bc_schema_location)
    filename
      |> File.read!
      |> JSON.decode!
      |> Map.get(content_type)
  end

end
