defmodule TdBgWeb.BusinessConceptVersionController do
  use TdBgWeb, :controller
  use TdBg.Hypermedia, :controller
  use PhoenixSwagger

  import Canada, only: [can?: 2]

  alias TdBg.BusinessConcepts
  alias TdBg.BusinessConcepts.BusinessConcept
  alias TdBg.BusinessConcepts.BusinessConceptVersion
  alias TdBgWeb.ErrorView
  alias TdBgWeb.SwaggerDefinitions
  alias TdBg.Permissions
  alias TdBg.Taxonomies
  alias TdBg.Templates

  @search_service Application.get_env(:td_bg, :elasticsearch)[:search_service]

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

  swagger_path :delete do
    delete "/business_concept_versions/{id}"
    description "Delete a business concept version"
    produces "application/json"
    parameters do
      id :path, :integer, "Business Concept Version ID", required: true
    end
    response 204, "No Content"
    response 400, "Client Error"
  end

  def delete(conn, %{"id" => id}) do
    business_concept_version = BusinessConcepts.get_business_concept_version!(id)
    user = conn.assigns.current_user
    with true <- can?(user, delete(business_concept_version)),
         {:ok, %BusinessConceptVersion{}} <- BusinessConcepts.delete_business_concept_version(business_concept_version) do
      @search_service.delete_search(business_concept_version)
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
    post "/business_concept_versions/{id}/send_for_approval"
    description "Submit a draft business concept for approval"
    produces "application/json"
    parameters do
      id :path, :integer, "Business Concept Version ID", required: true
    end
    response 200, "OK", Schema.ref(:BusinessConceptResponse)
    response 403, "User is not authorized to perform this action"
    response 422, "Business concept invalid state"
  end

  def send_for_approval(conn, %{"business_concept_version_id" => id}) do
    business_concept_version = BusinessConcepts.get_business_concept_version!(id)
    draft = BusinessConcept.status.draft
    case {business_concept_version.status, business_concept_version.current} do
      {^draft, true} ->
        user = conn.assigns.current_user
        send_for_approval(conn, user, business_concept_version)
      _ ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ErrorView, :"422.json")
    end
  end

  swagger_path :publish do
    post "/business_concept_versions/{id}/publish"
    description "Publish a business concept which is pending approval"
    produces "application/json"
    parameters do
      id :path, :integer, "Business Concept Version ID", required: true
    end
    response 200, "OK", Schema.ref(:BusinessConceptResponse)
    response 403, "User is not authorized to perform this action"
    response 422, "Business concept invalid state"
  end

  def publish(conn, %{"business_concept_version_id" => id}) do
    business_concept_version = BusinessConcepts.get_business_concept_version!(id)
    pending_approval = BusinessConcept.status.pending_approval
    case {business_concept_version.status, business_concept_version.current} do
      {^pending_approval, true} ->
        user = conn.assigns.current_user
        publish(conn, user, business_concept_version)
      _ ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ErrorView, :"422.json")
    end
  end

  swagger_path :reject do
    post "/business_concept_versions/{id}/reject"
    description "Reject a business concept which is pending approval"
    produces "application/json"
    parameters do
      id :path, :integer, "Business Concept Version ID", required: true
      reject_reason :body, :string, "Rejection reason"
    end
    response 200, "OK", Schema.ref(:BusinessConceptResponse)
    response 403, "User is not authorized to perform this action"
    response 422, "Business concept invalid state"
  end

  def reject(conn, %{"business_concept_version_id" => id} = params) do
    business_concept_version = BusinessConcepts.get_business_concept_version!(id)
    pending_approval = BusinessConcept.status.pending_approval
    case {business_concept_version.status, business_concept_version.current} do
      {^pending_approval, true} ->
        user = conn.assigns.current_user
        reject(conn, user, business_concept_version, Map.get(params, "reject_reason"))
      _ ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ErrorView, :"422.json")
    end
  end

  swagger_path :undo_rejection do
    post "/business_concept_versions/{id}/undo_rejection"
    description "Create a draft from a rejected business concept"
    produces "application/json"
    parameters do
      id :path, :integer, "Business Concept Version ID", required: true
    end
    response 200, "OK", Schema.ref(:BusinessConceptResponse)
    response 403, "User is not authorized to perform this action"
    response 422, "Business concept invalid state"
  end

  def undo_rejection(conn, %{"business_concept_version_id" => id}) do
    business_concept_version = BusinessConcepts.get_business_concept_version!(id)
    rejected = BusinessConcept.status.rejected
    case {business_concept_version.status, business_concept_version.current} do
      {^rejected, true} ->
        user = conn.assigns.current_user
        undo_rejection(conn, user, business_concept_version)
      _ ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ErrorView, :"422.json")
    end
  end

  swagger_path :version do
    post "/business_concept_versions/{id}/version"
    description "Create a new draft from a published business concept"
    produces "application/json"
    parameters do
      id :path, :integer, "Business Concept Version ID", required: true
    end
    response 200, "OK", Schema.ref(:BusinessConceptResponse)
    response 403, "User is not authorized to perform this action"
    response 422, "Business concept invalid state"
  end

  def version(conn, %{"business_concept_version_id" => id}) do
    business_concept_version = BusinessConcepts.get_business_concept_version!(id)
    published = BusinessConcept.status.published
    case {business_concept_version.status, business_concept_version.current} do
      {^published, true} ->
        user = conn.assigns.current_user
        do_version(conn, user, business_concept_version)
      _ ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ErrorView, :"422.json")
    end
  end

  swagger_path :deprecate do
    post "/business_concept_versions/{id}/deprecate"
    description "Deprecate a published business concept"
    produces "application/json"
    parameters do
      id :path, :integer, "Business Concept Version ID", required: true
    end
    response 200, "OK", Schema.ref(:BusinessConceptResponse)
    response 403, "User is not authorized to perform this action"
    response 422, "Business concept invalid state"
  end

  def deprecate(conn, %{"business_concept_version_id" => id}) do
    business_concept_version = BusinessConcepts.get_business_concept_version!(id)
    published = BusinessConcept.status.published
    case {business_concept_version.status, business_concept_version.current} do
      {^published, true} ->
        user = conn.assigns.current_user
        deprecate(conn, user, business_concept_version)
      _ ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ErrorView, :"422.json")
    end
  end

  defp send_for_approval(conn, user, business_concept_version) do
    update_status(conn, business_concept_version, BusinessConcept.status.pending_approval, can?(user, send_for_approval(business_concept_version)))
  end

  defp undo_rejection(conn, user, business_concept_version) do
    update_status(conn, business_concept_version, BusinessConcept.status.draft, can?(user, undo_rejection(business_concept_version)))
  end

  defp publish(conn, user, business_concept_version) do
    with true <- can?(user, publish(business_concept_version)),
         {:ok, %{published: %BusinessConceptVersion{} = concept}} <-
                    BusinessConcepts.publish_business_concept_version(business_concept_version) do
       render(conn, "show.json", business_concept_version: concept, hypermedia: hypermedia("business_concept_version", conn, concept))
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
       @search_service.put_search(business_concept_version)
       render(conn, "show.json", business_concept_version: concept, hypermedia: hypermedia("business_concept_version", conn, concept))
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
    update_status(conn, business_concept_version, BusinessConcept.status.deprecated, can?(user, deprecate(business_concept_version)))
  end

  defp update_status(conn, business_concept_version, status, authorized) do
    attrs = %{status: status}
    with true <- authorized,
         {:ok, %BusinessConceptVersion{} = concept} <-
           BusinessConcepts.update_business_concept_version_status(business_concept_version, attrs) do
       @search_service.put_search(business_concept_version)
       render(conn, "show.json", business_concept_version: concept, hypermedia: hypermedia("business_concept_version", conn, concept))
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
    business_concept = business_concept_version.business_concept
    concept_type = business_concept.type
    %{:content => content_schema} = Templates.get_template_by_name(concept_type)

    business_concept = business_concept
    |> Map.put("last_change_by", user.id)
    |> Map.put("last_change_at", DateTime.utc_now())

    draft_attrs = Map.from_struct(business_concept_version)
    draft_attrs = draft_attrs
    |> Map.put("business_concept", business_concept)
    |> Map.put("content_schema", content_schema)
    |> Map.put("last_change_by", user.id)
    |> Map.put("last_change_at", DateTime.utc_now())
    |> Map.put("status", BusinessConcept.status.draft)
    |> Map.put("version", business_concept_version.version + 1)

    with true <- can?(user, version(business_concept_version)),
         {:ok, %{current: %BusinessConceptVersion{} = new_version}}
            <- BusinessConcepts.version_business_concept(business_concept_version, draft_attrs) do
      conn
        |> put_status(:created)
        |> render("show.json", business_concept_version: new_version, hypermedia: hypermedia("business_concept_version", conn, new_version))
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

  swagger_path :taxonomy_roles do
    get "/business_concepts/{business_concept_version_id}/taxonomy_roles"
    description "Lists all the roles within the taxonomy of a given business concept"
    produces "application/json"
    parameters do
      business_concept_version_id :path, :integer, "Business Concept Version Id", required: true
    end
    response 200, "Ok", Schema.ref(:BusinessConceptTaxonomyResponse)
    response 403, "Invalid authorization"
    response 422, "Unprocessable Entity"
  end

  def taxonomy_roles(conn, %{"business_concept_version_id" => id}) do
    # We should fetch the user in order to check its permissions over the
    # current version of the business concept
    user = conn.assigns.current_user
    # First of all we should retrieve the business concept for a
    business_concept_version =
      BusinessConcepts.get_business_concept_version!(id)
    with true <- can?(user, view_business_concept(business_concept_version)) do
      business_concept = business_concept_version.business_concept
      business_concept_taxonomy =
        get_taxonomy_levels_from_business_concept(business_concept.domain_id)
        render(conn, "index_business_concept_taxonomy.json",
          business_concept_taxonomy: business_concept_taxonomy)
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

  defp get_taxonomy_levels_from_business_concept(domain_id, acc \\ [])
  defp get_taxonomy_levels_from_business_concept(nil, acc) do
    acc
  end
  defp get_taxonomy_levels_from_business_concept(domain_id, acc) do
    domain = Taxonomies.get_domain!(domain_id)
    acl_list = Permissions.get_list_acl_from_domain(domain)
    acc = case acl_list do
        [] -> acc
        acl_list -> acc ++ [%{domain_id: domain_id, domain_name: domain.name, roles: acl_list}]
      end
    get_taxonomy_levels_from_business_concept(domain.parent_id, acc)
  end

end
