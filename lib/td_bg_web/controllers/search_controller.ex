defmodule TdBgWeb.SearchController do
  use TdBgWeb, :controller
  import Canada, only: [can?: 2]

  alias TdBg.BusinessConcepts.BusinessConcept
  alias TdBgWeb.ErrorView

  alias TdBg.Search.Indexer

  def reindex_all(conn, _params) do
    claims = conn.assigns[:current_resource]

    if can?(claims, reindex_all(BusinessConcept)) do
      Indexer.reindex(:all)

      send_resp(conn, :accepted, "")
    else
      conn
      |> put_status(:forbidden)
      |> put_view(ErrorView)
      |> render("403.json")
    end
  end
end
