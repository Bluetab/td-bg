defmodule TrueBGWeb.UserControllerTest do
  use TrueBGWeb.ConnCase

  alias TrueBG.Accounts
  alias TrueBG.Accounts.User

  @create_attrs %{password: "some password_hash", user_name: "some user_name"}
  @update_attrs %{password: "some updated password_hash", user_name: "some updated user_name"}
  @invalid_attrs %{password: nil, user_name: nil}
  @admin_user_name "app-admin"

  def fixture(:user) do
    {:ok, user} = Accounts.create_user(@create_attrs)
    user
  end

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    test "lists all users", %{conn: conn} do
      conn = get conn, user_path(conn, :index)
      [admin_user|_tail] = json_response(conn, 200)["data"]
      assert admin_user["user_name"] == @admin_user_name
    end
  end

  describe "create user" do
    test "renders user when data is valid", %{conn: conn} do
      conn = post conn, user_path(conn, :create), user: @create_attrs
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get conn, user_path(conn, :show, id)
      user_data = json_response(conn, 200)["data"]
      assert user_data["id"] == id && user_data["user_name"] == "some user_name"

      # assert json_response(conn, 200)["data"] == %{
      #   "id" => id,
      #   "password_hash" => "some password",
      #   "user_name" => "some user_name"}
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post conn, user_path(conn, :create), user: @invalid_attrs
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update user" do
    setup [:create_user]

    test "renders user when data is valid", %{conn: conn, user: %User{id: id} = user} do
      conn = put conn, user_path(conn, :update, user), user: @update_attrs
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get conn, user_path(conn, :show, id)
      user_data = json_response(conn, 200)["data"]
      assert user_data["id"] == id && user_data["user_name"] == "some updated user_name"

      # assert json_response(conn, 200)["data"] == %{
      #   "id" => id,
      #   "password" => "some updated password",
      #   "user_name" => "some updated user_name"}
    end

    test "renders errors when data is invalid", %{conn: conn, user: user} do
      conn = put conn, user_path(conn, :update, user), user: @invalid_attrs
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete user" do
    setup [:create_user]

    test "deletes chosen user", %{conn: conn, user: user} do
      conn = delete conn, user_path(conn, :delete, user)
      assert response(conn, 204)
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
