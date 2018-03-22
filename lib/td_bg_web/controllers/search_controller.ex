defmodule TdBgWeb.SearchController do
  use TdBgWeb, :controller
  alias TdBg.Search

  def search(conn, %{"search_id" => index_name}) do
    %{body_params: query} = conn
    Search.search(index_name, query)
    conn
  end
end
