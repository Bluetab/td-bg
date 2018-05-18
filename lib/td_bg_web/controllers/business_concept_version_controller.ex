defmodule TdBgWeb.BusinessConceptVersionController do
  use TdBgWeb, :controller
  use TdBg.Hypermedia, :controller
  use PhoenixSwagger

  import Canada, only: [can?: 2]

  alias TdBg.BusinessConcepts
  alias TdBg.BusinessConcepts.BusinessConcept
  alias TdBgWeb.ErrorView
  alias TdBgWeb.SwaggerDefinitions
  alias TdBg.Permissions

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
    render(conn, "index.json", business_concept_versions: business_concept_versions, hypermedia: hypermedia("business_concept_version", conn, business_concept_versions))
  end

  swagger_path :versions do
    get "/business_concepts/{business_concept_id}/versions"
    description "List Business Concept Versions"
    parameters do
      business_concept_id :path, :integer, "Business Concept ID", required: true
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
      render(conn, "index.json", business_concept_versions: business_concept_versions, hypermedia: hypermedia("business_concept_version", conn, business_concept_versions))
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
      true -> BusinessConcept.status_values
      false ->
        permissions_to_status = BusinessConcept.permissions_to_status
        %{user_id: user.id, domain_id:  business_concept.domain_id}
        |> Permissions.get_permissions_in_resource
        |> Enum.reduce([], fn(permission, acc) ->
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
    get "/business_concept_versions/{id}"
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
    render(conn, "show.json", business_concept_version: business_concept_version, hypermedia: hypermedia("business_concept_version", conn, business_concept_version))
  end

  def send_for_approval(conn, %{"id" => id}) do
    business_concept_version = BusinessConcepts.get_business_concept_version!(id)
    # TODO: Send for approval
    render(conn, "show.json", business_concept_version: business_concept_version, hypermedia: hypermedia("business_concept", conn, business_concept_version))
  end

end
