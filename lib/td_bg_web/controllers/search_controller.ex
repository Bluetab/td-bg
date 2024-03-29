defmodule TdBgWeb.SearchController do
  use TdBgWeb, :controller
  import Canada, only: [can?: 2]
  use PhoenixSwagger
  alias TdBg.BusinessConcepts.BusinessConcept
  alias TdBgWeb.ErrorView

  alias TdCore.Search

  swagger_path :reindex_all do
    description("Reindex all ES indexes with DB content")
    produces("application/json")
    response(202, "Accepted")
    response(403, "Unauthorized")
    response(500, "Client Error")
  end

  def reindex_all(conn, _params) do
    claims = conn.assigns[:current_resource]

    if can?(claims, reindex_all(BusinessConcept)) do
      Search.IndexWorker.reindex(:concepts, :all)

      send_resp(conn, :accepted, "")
    else
      conn
      |> put_status(:forbidden)
      |> put_view(ErrorView)
      |> render("403.json")
    end
  end
end
