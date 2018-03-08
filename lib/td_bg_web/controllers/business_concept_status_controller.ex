defmodule TdBGWeb.BusinessConceptStatusController do
  require Logger
  use TdBGWeb, :controller
  use PhoenixSwagger

  import Canada, only: [can?: 2]

  alias TdBG.BusinessConcepts
  alias TdBG.BusinessConcepts.BusinessConcept
  alias TdBG.BusinessConcepts.BusinessConceptVersion
  alias TdBGWeb.BusinessConceptView
  alias TdBGWeb.ErrorView
  alias TdBGWeb.SwaggerDefinitions

  action_fallback TdBGWeb.FallbackController

  plug :load_resource, model: BusinessConcept, id_name: "business_concept_id", persisted: true, only: [:update]

  def swagger_definitions do
    SwaggerDefinitions.business_concept_definitions()
  end

  swagger_path :update do
    patch "/business_concepts/{business_concept_id}/status"
    description "Updates Business Ccncept status"
    produces "application/json"
    parameters do
      business_concept :body, Schema.ref(:BusinessConceptStatusUpdate), "Business Concept status update attrs"
      business_concept_id :path, :integer, "Business Concept ID", required: true
    end
    response 200, "OK", Schema.ref(:BusinessConceptResponse)
    response 400, "Client Error"
  end

  def update(conn, %{"business_concept_id" => id, "business_concept" => %{"status" => new_status} = business_concept_params}) do

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
       render(conn, BusinessConceptView, "show.json", business_concept: concept)
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
       render(conn, BusinessConceptView, "show.json", business_concept: concept)
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
         render(conn, BusinessConceptView, "show.json", business_concept: concept)
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
         render(conn, BusinessConceptView, "show.json", business_concept: concept)
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

end
