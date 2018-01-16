defmodule TrueBGWeb.SessionControllerTest do
  use TrueBGWeb.ConnCase

  alias TrueBG.Accounts
  alias Comeonin.Bcrypt

  @create_attrs %{password_hash: Bcrypt.hashpwsalt("temporal"),
                 user_name: "usuariotemporal"}
  @valid_attrs %{password: "temporal",
                 user_name: "usuariotemporal"}
  @invalid_attrs %{password: "invalido",
                 user_name: "usuariotemporal"}


  def fixture(:user) do
    {:ok, user} = Accounts.create_user(@create_attrs)
    user
  end

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "create session " do
    setup [:create_user]

    test "create valid user session", %{conn: conn} do
      conn = post conn, session_path(conn, :create), user: @valid_attrs
      assert conn.status ==  201
    end

    test "create invalid user session", %{conn: conn} do
      conn = post conn, session_path(conn, :create), user: @invalid_attrs
      assert conn.status ==  401
    end

  end

  defp create_user(_) do
    user = fixture(:user)
    {:ok, user: user}
  end
end
