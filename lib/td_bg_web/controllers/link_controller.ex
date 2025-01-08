defmodule TdBgWeb.BusinessConceptLinkController do
  use TdBgWeb, :controller
  use TdHypermedia, :controller

  import Canada, only: [can?: 2]

  require Logger

  alias TdBg.BusinessConcepts.Links
  alias TdBgWeb.ErrorView

  action_fallback(TdBgWeb.FallbackController)

  def delete(conn, %{"id" => id}) do
    claims = conn.assigns[:current_resource]

    with {:ok, link} <- Links.get(id),
         true <- can?(claims, delete(link)),
         {:ok, _} <- Links.delete(id) do
      send_resp(conn, :accepted, "")
    else
      false ->
        conn
        |> put_status(:forbidden)
        |> put_view(ErrorView)
        |> render("403.json")

      {:error, error} ->
        Logger.error("While reading link... #{inspect(error)}")
        send_resp(conn, :unprocessable_entity, Jason.encode!(error))

      error ->
        Logger.error("While reading link... #{inspect(error)}")

        conn
        |> put_status(:unprocessable_entity)
        |> put_view(ErrorView)
        |> render("422.json")
    end
  end

  def create_concept_link(conn, _params) do
    # This method is only used to generate an action in the business_concept_version hypermedia response
    send_resp(conn, :accepted, "")
  end

  def create_structure_link(conn, _params) do
    # This method is only used to generate an action in the business_concept_version hypermedia response
    send_resp(conn, :accepted, "")
  end
end
