defmodule TdBgWeb.UserSearchFilterControllerTest do
  use TdBgWeb.ConnCase

  alias TdBg.UserSearchFilters

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
    [conn: put_req_header(conn, "accept", "application/json")]
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

    @tag authentication: [
           user_name: "non_admin",
           permissions: ["view_published_business_concepts"]
         ]
    test "lists current user user_search_filters with global filters", %{
      conn: conn,
      claims: %{user_id: user_id}
    } do
      %{id: id1} = insert(:user_search_filter, name: "a", user_id: user_id)
      %{id: id2} = insert(:user_search_filter, name: "b", is_global: true)
      insert(:user_search_filter, name: "c", is_global: false)

      assert %{"data" => data} =
               conn
               |> get(Routes.user_search_filter_path(conn, :index_by_user))
               |> json_response(:ok)

      assert_lists_equal(data, [id1, id2], &(&1["id"] == &2))
    end

    @tag authentication: [
           user_name: "non_admin",
           permissions: ["view_published_business_concepts"]
         ]
    test "global filters with taxonomy will only appear for users with permission on any filter domain",
         %{
           conn: conn,
           claims: %{user_id: user_id},
           domain: %{id: domain_id}
         } do
      %{id: id1} = insert(:user_search_filter, user_id: user_id)

      %{id: id2} =
        insert(:user_search_filter,
          filters: %{"taxonomy" => [domain_id]},
          is_global: true
        )

      insert(:user_search_filter,
        filters: %{"taxonomy" => [domain_id + 1]},
        is_global: true
      )

      insert(:user_search_filter, is_global: false)

      assert %{"data" => data} =
               conn
               |> get(Routes.user_search_filter_path(conn, :index_by_user))
               |> json_response(:ok)

      assert_lists_equal(data, [id1, id2], &(&1["id"] == &2))
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
