defmodule TrueBGWeb.UserControllerTest do
  use TrueBGWeb.ConnCase

  alias TrueBG.Accounts
  alias TrueBG.Accounts.User

  @create_attrs %{password: "some password_hash", user_name: "some user_name", is_admin: false}
  @update_attrs %{password: "some updated password_hash", user_name: "some updated user_name"}
  @update_is_admin %{user_name: "some updated user_name", is_admin: true}
  @invalid_attrs %{password: nil, user_name: nil}
  @admin_user_name "app-admin"

  def fixture(:user) do
    {:ok, user} = Accounts.create_user(@create_attrs)
    user
  end

  def put_auth_headers(conn, jwt) do
    conn
      |> put_req_header("content-type", "application/json")
      |> put_req_header("authorization", "Bearer #{jwt}")
  end

  describe "index with authenticated user tag" do
    @tag authenticated_user: @admin_user_name
    test "list all users with some user name", %{conn: conn, jwt: jwt} do
      conn = conn
             |> put_auth_headers(jwt)
      conn = get conn, user_path(conn, :index)
      [admin_user|_tail] = json_response(conn, 200)["data"]
      assert admin_user["user_name"] == @admin_user_name
    end
  end

  describe "index" do
    @tag :admin_authenticated
    test "list all users", %{conn: conn, jwt: jwt} do
      conn = conn
        |> put_auth_headers(jwt)
      conn = get conn, user_path(conn, :index)
      [admin_user|_tail] = json_response(conn, 200)["data"]
      assert admin_user["user_name"] == @admin_user_name
    end
  end

  describe "create user" do
    @tag :admin_authenticated
    test "renders user when data is valid", %{conn: conn, jwt: jwt} do
      conn = conn
             |> put_auth_headers(jwt)
      conn = post conn, user_path(conn, :create), user: @create_attrs
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = conn
             |> recycle()
             |> put_auth_headers(jwt)

      conn = get conn, user_path(conn, :show, id)
      user_data = json_response(conn, 200)["data"]
      assert user_data["id"] == id && user_data["user_name"] == "some user_name"

      # assert json_response(conn, 200)["data"] == %{
      #   "id" => id,
      #   "password_hash" => "some password",
      #   "user_name" => "some user_name"}
    end

    @tag :admin_authenticated
    test "renders errors when data is invalid", %{conn: conn, jwt: jwt} do
      conn = conn
             |> put_auth_headers(jwt)
      conn = post conn, user_path(conn, :create), user: @invalid_attrs
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update user" do
    setup [:create_user]

    @tag :admin_authenticated
    test "renders user when data is valid", %{conn: conn, jwt: jwt, user: %User{id: id} = user} do
      conn = conn
        |> put_auth_headers(jwt)
      conn = put conn, user_path(conn, :update, user), user: @update_attrs
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = conn
             |> recycle()
             |> put_auth_headers(jwt)

      conn = get conn, user_path(conn, :show, id)
      user_data = json_response(conn, 200)["data"]
      assert user_data["id"] == id && user_data["user_name"] == "some updated user_name"

      end

      # assert json_response(conn, 200)["data"] == %{
      #   "id" => id,
      #   "password" => "some updated password",
      #   "user_name" => "some updated user_name"}

    @tag :admin_authenticated
    test "renders errors when data is invalid", %{conn: conn, jwt: jwt, user: user} do
      conn = conn
             |> put_auth_headers(jwt)
      conn = put conn, user_path(conn, :update, user), user: @invalid_attrs
      assert json_response(conn, 422)["errors"] != %{}
    end

    @tag :admin_authenticated
    test "update user is admin flag", %{conn: conn, jwt: jwt, user: user} do
      conn = conn
             |> put_auth_headers(jwt)
      conn = put conn, user_path(conn, :update, user), user: @update_is_admin
      updated_user = json_response(conn, 200)["data"]
      persisted_user = Accounts.get_user_by_name(updated_user["user_name"])
      assert persisted_user.is_admin == @update_is_admin.is_admin
    end

  end

  describe "delete user" do
   setup [:create_user]

   @tag :admin_authenticated
   test "deletes chosen user", %{conn: conn, jwt: jwt,  user: user} do
     conn = conn
       |> put_auth_headers(jwt)
     conn = delete conn, user_path(conn, :delete, user)
     assert response(conn, 204)

     conn = conn
        |> recycle()
        |> put_auth_headers(jwt)

     assert_error_sent 404, fn ->
       get conn, user_path(conn, :show, user)
     end
   end
  end

  defp create_user(_) do
   user = fixture(:user)
    {:ok, user: user}
  end
end
