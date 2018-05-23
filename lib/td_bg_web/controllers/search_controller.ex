  defmodule TdBgWeb.SearchController do
  use TdBgWeb, :controller
  use PhoenixSwagger

  alias TdBg.Search
  alias TdBg.ESClientApi

  #  alias TdBgWeb.SwaggerDefinitions

  def search(%{body_params: query} = conn, %{"search_id" => index_name}) do
    resp = Search.search(index_name, query)
    json conn, %{data: resp}
  end

  swagger_path :create do
    post "/search"
    description "Creates ES indexes"
    produces "application/json"
    response 201, "Created"
    response 500, "Client Error"
  end
  def create(conn, _params) do
    ESClientApi.create_indexes
    send_resp(conn, :created, "")
  end

  swagger_path :delete do
    delete "/search"
    description "Deletes ES indexes"
    produces "application/json"
    response 204, "Deleted"
    response 500, "Client Error"
  end
  def delete(conn, _params) do
    ESClientApi.delete_indexes
    send_resp(conn, :no_content, "")
  end

  swagger_path :reindex_all do
    get "/search/reindex_all"
    description "Reindex all ES indexes with DB content"
    produces "application/json"
    response 200, "OK"
    response 500, "Client Error"
  end
  def reindex_all(conn, _params) do
    {:ok, _response} = Search.put_bulk_search(:domain)
    {:ok, _response} = Search.put_bulk_search(:business_concept)
    send_resp(conn, :ok, "")
  end

end
