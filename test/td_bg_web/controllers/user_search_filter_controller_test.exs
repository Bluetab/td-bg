defmodule TdBgWeb.UserSearchFilterControllerTest do
  use TdBgWeb.ConnCase

  alias TdBg.Permissions.MockPermissionResolver
  alias TdBg.UserSearchFilters

  setup_all do
    start_supervised(MockPermissionResolver)
    :ok
  end

  @create_attrs %{
    filters: %{country: ["Spa"]},
    name: "some name"
  }

  @invalid_attrs %{filters: nil, name: nil, user_id: nil}

  def fixture(:user_search_filter) do
    {:ok, user_search_filter} = UserSearchFilters.create_user_search_filter(@create_attrs)
    user_search_filter
  end

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    @tag authentication: [role: "admin"]
    test "lists all user_search_filters", %{conn: conn} do
      conn = get(conn, Routes.user_search_filter_path(conn, :index))
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "index by user" do
    @tag authentication: [role: "admin"]
    test "lists current user user_search_filters", %{conn: conn} do
      conn1 = get(conn, Routes.user_search_filter_path(conn, :index))

      current_user_id =
        conn1 |> Map.get(:assigns) |> Map.get(:current_resource) |> Map.get(:user_id)

      insert(:user_search_filter, user_id: 1)
      insert(:user_search_filter, user_id: 2)
      insert(:user_search_filter, name: "a", user_id: current_user_id)
      insert(:user_search_filter, name: "b", user_id: current_user_id)

      conn = get(conn, Routes.user_search_filter_path(conn, :index_by_user))
      user_filters = json_response(conn, 200)["data"]
      [user_id] = user_filters |> Enum.map(&Map.get(&1, "user_id")) |> Enum.uniq()
      assert user_id == current_user_id
      assert length(user_filters) == 2
    end
  end

  describe "create user_search_filter" do
    @tag authentication: [role: "admin"]
    test "renders user_search_filter when data is valid", %{conn: conn} do
      conn =
        post(conn, Routes.user_search_filter_path(conn, :create),
          user_search_filter: @create_attrs
        )

      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get(conn, Routes.user_search_filter_path(conn, :show, id))

      assert %{
               "id" => _,
               "filters" => %{},
               "name" => "some name",
               "user_id" => _
             } = json_response(conn, 200)["data"]
    end

    @tag authentication: [role: "admin"]
    test "renders errors when data is invalid", %{conn: conn} do
      conn =
        post(conn, Routes.user_search_filter_path(conn, :create),
          user_search_filter: @invalid_attrs
        )

      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete user_search_filter" do
    @tag authentication: [role: "admin"]
    test "deletes chosen user_search_filter", %{
      conn: conn
    } do
      conn1 =
        post(conn, Routes.user_search_filter_path(conn, :create),
          user_search_filter: @create_attrs
        )

      user_search_filter = conn1 |> Map.get(:assigns) |> Map.get(:user_search_filter)

      conn = delete(conn, Routes.user_search_filter_path(conn, :delete, user_search_filter))
      assert response(conn, 204)

      conn = get(conn, Routes.user_search_filter_path(conn, :show, user_search_filter))

      assert response(conn, 404)
    end
  end
end
