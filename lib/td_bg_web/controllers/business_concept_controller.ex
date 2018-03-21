defmodule TdBgWeb.BusinessConceptController do
  require Logger
  use TdBgWeb, :controller
  use PhoenixSwagger

  import Canada, only: [can?: 2]

  alias TdBg.BusinessConcepts
  alias TdBg.BusinessConcepts.BusinessConcept
  alias TdBg.BusinessConcepts.BusinessConceptVersion
  alias TdBg.Taxonomies.DataDomain
  alias TdBgWeb.ErrorView
  alias TdBgWeb.SwaggerDefinitions
  alias TdBg.SearchApi

  alias Poison, as: JSON

  plug :load_resource, model: DataDomain, id_name: "data_domain_id", persisted: true, only: :create
  plug :load_resource, model: BusinessConcept, id_name: "business_concept_id", persisted: true, only: [:update_status]

  action_fallback TdBgWeb.FallbackController

  def swagger_definitions do
    SwaggerDefinitions.business_concept_definitions()
  end

  swagger_path :index do
    get "/business_concepts"
    description "List Business Concepts"
    response 200, "OK", Schema.ref(:BusinessConceptsResponse)
  end

  def index(conn, _params) do
    business_concept_versions = BusinessConcepts.list_all_business_concept_versions()
    render(conn, "index.json", business_concepts: business_concept_versions)
  end

  swagger_path :index_children_business_concept do
    get "/data_domains/{id}/business_concepts"
    description "List Business Concepts children of Data Domain"
    produces "application/json"
    parameters do
      id :path, :integer, "Data Domain ID", required: true
    end
    response 200, "OK", Schema.ref(:BusinessConceptsResponse)
    response 400, "Client Error"
  end

  def index_children_business_concept(conn, %{"data_domain_id" => id}) do
    business_concept_vesions = BusinessConcepts.get_data_domain_children_versions!(id)
    render(conn, "index.json", business_concepts: business_concept_vesions)
  end

  swagger_path :create do
    post "/data_domains/{data_domain_id}/business_concept"
    description "Creates a Business Concept child of Data Domain"
    produces "application/json"
    parameters do
      business_concept :body, Schema.ref(:BusinessConceptCreate), "Business Concept create attrs"
      data_domain_id :path, :integer, "Data Domain ID", required: true
    end
    response 201, "Created", Schema.ref(:BusinessConceptResponse)
    response 400, "Client Error"
  end

  def create(conn, %{"business_concept" => business_concept_params}) do

    concept_type = Map.get(business_concept_params, "type")
    content_schema = get_content_schema(concept_type)

    concept_name = Map.get(business_concept_params, "name")

    user = conn.assigns.current_user
    data_domain = conn.assigns.data_domain

    business_concept_attrs = %{}
    |> Map.put("data_domain_id", data_domain.id)
    |> Map.put("type", concept_type)
    |> Map.put("last_change_by", user.id)
    |> Map.put("last_change_at", DateTime.utc_now())

    creation_attrs = business_concept_params
    |> Map.put("business_concept", business_concept_attrs)
    |> Map.put("content_schema", content_schema)
    |> Map.put("last_change_by", conn.assigns.current_user.id)
    |> Map.put("last_change_at", DateTime.utc_now())
    |> Map.put("status", BusinessConcept.status.draft)
    |> Map.put("version", 1)

    with true <- can?(user, create_business_concept(data_domain)),
         {:available} <- BusinessConcepts.check_business_concept_name_availability(concept_type, concept_name),
         {:ok, %BusinessConceptVersion{} = concept} <-
          BusinessConcepts.create_business_concept_version(creation_attrs) do
      conn = conn
      |> put_status(:created)
      |> put_resp_header("location", business_concept_path(conn, :show, concept.business_concept))
      |> render("show.json", business_concept: concept)
      SearchApi.put_search(concept)
      conn
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

  swagger_path :show do
    get "/business_concepts/{id}"
    description "Show Business Concepts"
    produces "application/json"
    parameters do
      id :path, :integer, "Business Concept ID", required: true
    end
    response 200, "OK", Schema.ref(:BusinessConceptResponse)
    response 400, "Client Error"
  end

  def show(conn, %{"id" => id}) do
    business_concept = BusinessConcepts.get_current_version_by_business_concept_id!(id)
    render(conn, "show.json", business_concept: business_concept)
  end

  swagger_path :update do
    put "/business_concepts/{id}"
    description "Updates Business Ccncepts"
    produces "application/json"
    parameters do
      business_concept :body, Schema.ref(:BusinessConceptUpdate), "Business Concept update attrs"
      id :path, :integer, "Business Concept ID", required: true
    end
    response 200, "OK", Schema.ref(:BusinessConceptResponse)
    response 400, "Client Error"
  end

  def update(conn, %{"id" => id, "business_concept" => business_concept_params}) do
    business_concept_version = BusinessConcepts.get_current_version_by_business_concept_id!(id)

    concept_type = business_concept_version.business_concept.type
    concept_name = Map.get(business_concept_params, "name")
    content_schema = get_content_schema(concept_type)

    user = conn.assigns.current_user

    business_concept_attrs = %{}
    |> Map.put("last_change_by", user.id)
    |> Map.put("last_change_at", DateTime.utc_now())

    update_params = business_concept_params
    |> Map.put("business_concept", business_concept_attrs)
    |> Map.put("content_schema", content_schema)
    |> Map.put("last_change_by", user.id)
    |> Map.put("last_change_at", DateTime.utc_now())

    with true <- can?(user, update(business_concept_version)),
         {:available} <- BusinessConcepts.check_business_concept_name_availability(concept_type, concept_name, id),
         {:ok, %BusinessConceptVersion{} = concept} <-
      BusinessConcepts.update_business_concept_version(business_concept_version,
                                                              update_params) do
      SearchApi.put_search(business_concept_version)
      render(conn, "show.json", business_concept: concept)
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
    delete "/business_concepts/{id}"
    description "Delete Business Concepts"
    produces "application/json"
    parameters do
      id :path, :integer, "Business Concept ID", required: true
    end
    response 204, "No Content"
    response 400, "Client Error"
  end

  def delete(conn, %{"id" => id}) do
    business_concept_version = BusinessConcepts.get_current_version_by_business_concept_id!(id)

    user = conn.assigns.current_user

    with true <- can?(user, delete(business_concept_version)),
         {:ok, %BusinessConceptVersion{}} <- BusinessConcepts.delete_business_concept_version(business_concept_version) do
      SearchApi.delete_search(business_concept_version)
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

  swagger_path :update_status do
    patch "/business_concepts/{business_concept_id}/status"
    description "Updates Business Ccncept status"
    produces "application/json"
    parameters do
      business_concept :body, Schema.ref(:BusinessConceptUpdateStatus), "Business Concept status update attrs"
      business_concept_id :path, :integer, "Business Concept ID", required: true
    end
    response 200, "OK", Schema.ref(:BusinessConceptResponse)
    response 400, "Client Error"
  end

  def update_status(conn, %{"business_concept_id" => id, "business_concept" => %{"status" => new_status} = business_concept_params}) do

    business_concept_version = BusinessConcepts.get_current_version_by_business_concept_id!(id)
    status = business_concept_version.status
    user = conn.assigns.current_user

    draft = BusinessConcept.status.draft
    rejected = BusinessConcept.status.rejected
    pending_approval = BusinessConcept.status.pending_approval
    published = BusinessConcept.status.published
    deprecated = BusinessConcept.status.deprecated

    case {status, new_status} do
      {^draft, ^pending_approval} ->
        send_for_approval(conn, user, business_concept_version, business_concept_params)
      {^pending_approval, ^published} ->
        publish(conn, user,  business_concept_version, business_concept_params)
      {^pending_approval, ^rejected} ->
        reject(conn, user,  business_concept_version, business_concept_params)
      {^rejected, ^pending_approval} ->
        send_for_approval(conn, user, business_concept_version, business_concept_params)
      {^published, ^deprecated} ->
        deprecate(conn, user, business_concept_version, business_concept_params)
      _ ->
        Logger.info "No status action for {#{status}, #{new_status}} combination"
        conn
        |> put_status(:unprocessable_entity)
        |> render(ErrorView, :"422.json")
    end
  end

  defp send_for_approval(conn, user, business_concept_version, _business_concept_params) do
    attrs = %{status: BusinessConcept.status.pending_approval}
    with true <- can?(user, send_for_approval(business_concept_version)),
         {:ok, %BusinessConceptVersion{} = concept} <-
           BusinessConcepts.update_business_concept_version_status(business_concept_version, attrs) do
       SearchApi.put_search(business_concept_version)
       render(conn, "show.json", business_concept: concept)
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

  defp reject(conn, user, business_concept_version, business_concept_params) do
    attrs = %{reject_reason: Map.get(business_concept_params, "reject_reason")}
    with true <- can?(user, reject(business_concept_version)),
         {:ok, %BusinessConceptVersion{} = concept} <-
           BusinessConcepts.reject_business_concept_version(business_concept_version, attrs) do
       SearchApi.put_search(business_concept_version)
       render(conn, "show.json", business_concept: concept)
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

  defp publish(conn, user, business_concept_version, _business_concept_params) do
    with true <- can?(user, publish(business_concept_version)),
         {:ok, %{published: %BusinessConceptVersion{} = concept}} <-
                    BusinessConcepts.publish_business_concept_version(business_concept_version) do
         render(conn, "show.json", business_concept: concept)
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

  defp deprecate(conn, user, business_concept_version, _business_concept_params) do
    attrs = %{status: BusinessConcept.status.deprecated}
    with true <- can?(user, deprecate(business_concept_version)),
          {:ok, %BusinessConceptVersion{} = concept} <-
            BusinessConcepts.update_business_concept_version_status(business_concept_version, attrs) do
         SearchApi.put_search(business_concept_version)
         render(conn, "show.json", business_concept: concept)
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

  defp get_content_schema(content_type) do
    filename = Application.get_env(:td_bg, :bc_schema_location)
    filename
      |> File.read!
      |> JSON.decode!
      |> Map.get(content_type)
  end
end
