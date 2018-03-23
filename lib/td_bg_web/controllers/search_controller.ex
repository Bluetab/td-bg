defmodule TdBgWeb.SearchController do
  use TdBgWeb, :controller
  alias TdBg.Search

  def search(%{body_params: query} = conn, %{"search_id" => index_name}) do
    Search.search(index_name, query)
    conn
  end

end
