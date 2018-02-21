defmodule TrueBGWeb.BusinessConceptStatusController do
  use TrueBGWeb, :controller

  import Canada, only: [can?: 2]

  alias TrueBG.BusinessConcepts
  alias TrueBG.BusinessConcepts.BusinessConcept
  alias TrueBGWeb.BusinessConceptView
  alias TrueBGWeb.ErrorView

  action_fallback TrueBGWeb.FallbackController

  plug :load_resource, model: BusinessConcept, id_name: "business_concept_id", persisted: true, only: [:update]

  def update(conn, %{"status" => new_status} = params) do

    business_concept = conn.assigns.business_concept
    status = business_concept.status
    user = conn.assigns.current_user

    draft = BusinessConcept.status.draft
    rejected = BusinessConcept.status.rejected
    pending_approval = BusinessConcept.status.pending_approval
    published = BusinessConcept.status.published

    case {status, new_status} do
      {^draft, ^pending_approval} ->
        send_for_approval(conn, user, business_concept, params)
      {^pending_approval, ^published} ->
        publish(conn, user,  business_concept, params)
      {^pending_approval, ^rejected} ->
        reject(conn, user,  business_concept, params)
      _ ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ErrorView, :"422.json")
    end
  end

  defp send_for_approval(conn, user, business_concept, _parmas) do
    case can?(user, send_for_approval(business_concept)) do
      true -> do_send_for_approval(conn, business_concept)
      _ ->
         conn
           |> put_status(:forbidden)
           |> render(ErrorView, :"403.json")
    end
  end

  defp do_send_for_approval(conn, business_concept) do
    attrs = %{status: BusinessConcept.status.pending_approval}
    with {:ok, %BusinessConcept{} = concept} <-
          BusinessConcepts.update_business_concept_status(business_concept, attrs) do
      render(conn, BusinessConceptView, "show.json", business_concept: concept)
    end
  end

  defp reject(conn, user, business_concept, params) do
    case can?(user, reject(business_concept)) do
      true -> do_reject(conn, business_concept, params)
      _ ->
         conn
           |> put_status(:forbidden)
           |> render(ErrorView, :"403.json")
    end
  end

  defp do_reject(conn, business_concept, params) do
    attrs = %{reject_reason: Map.get(params, "reject_reason")}
    with {:ok, %BusinessConcept{} = concept} <-
          BusinessConcepts.reject_business_concept(business_concept, attrs) do
      render(conn, BusinessConceptView, "show.json", business_concept: concept)
    end
  end

  defp publish(conn, user, business_concept, _parmas) do
    case can?(user, publish(business_concept)) do
      true -> do_publish(conn, business_concept)
      _ ->
         conn
           |> put_status(:forbidden)
           |> render(ErrorView, :"403.json")
    end
  end

  defp do_publish(conn, business_concept) do
    with {:ok, %{published: %BusinessConcept{} = concept}} <-
                  BusinessConcepts.publish_business_concept(business_concept) do
      render(conn, BusinessConceptView, "show.json", business_concept: concept)
    end
  end
end
