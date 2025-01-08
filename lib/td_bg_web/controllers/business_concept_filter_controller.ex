defmodule TdBgWeb.BusinessConceptFilterController do
  use TdBgWeb, :controller

  alias TdBg.BusinessConcept.Search

  require Logger

  action_fallback(TdBgWeb.FallbackController)

  def index(conn, _params) do
    claims = conn.assigns[:current_resource]
    filters = Search.get_filter_values(claims, %{})
    render(conn, "show.json", filters: filters)
  end

  def search(conn, params) do
    claims = conn.assigns[:current_resource]
    filters = Search.get_filter_values(claims, params)
    render(conn, "show.json", filters: filters)
  end
end
