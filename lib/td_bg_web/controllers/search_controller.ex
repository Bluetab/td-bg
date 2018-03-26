defmodule TdBgWeb.SearchController do
  use TdBgWeb, :controller
  alias TdBg.Search
  alias TdBg.ESClientApi

  def search(%{body_params: query} = conn, %{"search_id" => index_name}) do
    resp = Search.search(index_name, query)
    json conn, %{data: resp}
  end

  def create(conn, _params) do
    ESClientApi.create_indexes
    json conn, %{data: %{status: "created"}}
  end

  def delete(conn, _params) do
    ESClientApi.delete_indexes
    json conn, %{data: %{status: "deleted"}}
  end

end
