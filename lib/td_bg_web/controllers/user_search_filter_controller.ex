defmodule TdBgWeb.UserSearchFilterController do
  use TdBgWeb, :controller

  alias TdBg.UserSearchFilters
  alias TdBg.UserSearchFilters.UserSearchFilter
  alias TdBgWeb.ErrorView

  action_fallback TdBgWeb.FallbackController

  def index(conn, _params) do
    user_search_filters = UserSearchFilters.list_user_search_filters()
    render(conn, "index.json", user_search_filters: user_search_filters)
  end

  def index_by_user(conn, _params) do
    claims = conn.assigns[:current_resource]

    user_search_filters = UserSearchFilters.list_user_search_filters(claims)
    render(conn, "index.json", user_search_filters: user_search_filters)
  end

  def create(conn, %{"user_search_filter" => user_search_filter_params}) do
    %{user_id: user_id} = conn.assigns[:current_resource]

    create_params = Map.put(user_search_filter_params, "user_id", user_id)

    with {:ok, %UserSearchFilter{} = user_search_filter} <-
           UserSearchFilters.create_user_search_filter(create_params) do
      conn
      |> put_status(:created)
      |> put_resp_header(
        "location",
        Routes.user_search_filter_path(conn, :show, user_search_filter)
      )
      |> render("show.json", user_search_filter: user_search_filter)
    end
  end

  def show(conn, %{"id" => id}) do
    user_search_filter = UserSearchFilters.get_user_search_filter!(id)
    render(conn, "show.json", user_search_filter: user_search_filter)
  rescue
    _e in Ecto.NoResultsError ->
      conn
      |> put_status(:not_found)
      |> put_view(ErrorView)
      |> render("404.json")
  end

  def delete(conn, %{"id" => id}) do
    %{user_id: user_id} = conn.assigns[:current_resource]
    user_search_filter = UserSearchFilters.get_user_search_filter!(id)

    with true <- user_id == user_search_filter.user_id,
         {:ok, %UserSearchFilter{}} <-
           UserSearchFilters.delete_user_search_filter(user_search_filter) do
      send_resp(conn, :no_content, "")
    else
      false ->
        conn
        |> put_status(:forbidden)
        |> put_view(ErrorView)
        |> render("403.json")
    end
  rescue
    _e in Ecto.NoResultsError ->
      conn
      |> put_status(:not_found)
      |> put_view(ErrorView)
      |> render("404.json")
  end
end
