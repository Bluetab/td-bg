defmodule TdBgWeb.SearchController do
  use TdBgWeb, :controller
  import Canada, only: [can?: 2]
  use PhoenixSwagger
  alias TdBg.BusinessConcepts.BusinessConcept
  alias TdBgWeb.ErrorView

  @index_worker Application.get_env(:td_bg, :index_worker)

  swagger_path :reindex_all do
    description("Reindex all ES indexes with DB content")
    produces("application/json")
    response(202, "Accepted")
    response(403, "Unauthorized")
    response(500, "Client Error")
  end

  def reindex_all(conn, _params) do
    user = conn.assigns[:current_user]

    with true <- can?(user, reindex_all(BusinessConcept)) do
      @index_worker.reindex(:all)
      send_resp(conn, :accepted, "")
    else
      false ->
        conn
        |> put_status(:forbidden)
        |> put_view(ErrorView)
        |> render("403.json")

      _error ->
        conn
        |> put_status(:internal_server_error)
        |> put_view(ErrorView)
        |> render("500.json")
    end
  end
end
