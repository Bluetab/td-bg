defmodule TrueBGWeb.Authentication do
  @moduledoc """
  This module defines the functions required to
  add auth headers to requests
  """
  alias Phoenix.ConnTest
  alias TrueBG.Auth.Guardian
  alias Poison, as: JSON
  alias TrueBG.Accounts.User
  import Plug.Conn
  import TrueBGWeb.Router.Helpers
  @endpoint TrueBGWeb.Endpoint
  @headers {"Content-type", "application/json"}

  def put_auth_headers(conn, jwt) do
    conn
    |> put_req_header("content-type", "application/json")
    |> put_req_header("authorization", "Bearer #{jwt}")
  end

  def recycle_and_put_headers(conn) do
    authorization_header = List.first(get_req_header(conn, "authorization"))
    conn
    |> ConnTest.recycle()
    |> put_req_header("authorization", authorization_header)
    end

  def create_user_auth_conn(user) do
    {:ok, jwt, full_claims} = Guardian.encode_and_sign(user)
    conn = ConnTest.build_conn()
    conn = put_auth_headers(conn, jwt)
    {:ok, %{conn: conn, jwt: jwt, claims: full_claims}}
  end

  def get_header(token) do
    [@headers, {"authorization", "Bearer #{token}"}]
  end

  def session_create(user_name, _user_password) do
    if user_name == "app-admin" do
      user  = create_user(user_name, true)
      token = build_user_token(user)
      {:ok, 201, %{"token" => token}}
    else
      user = create_user(user_name)
      token = build_user_token(user)
      {:ok, 201, %{"token" => token}}
    end
  end

  def create_user(user_name, is_admin \\ false) do
    id = Integer.mod(:binary.decode_unsigned(user_name), 100_000)
    %TrueBG.Accounts.User{id: id, is_admin: is_admin, user_name: user_name}
  end

  def build_user_token(%User{} = user) do
      case Guardian.encode_and_sign(user) do
        {:ok, jwt, _full_claims} -> jwt
        _ -> raise "Problems encoding and signing a user"
      end
  end

  def build_user_token(user_name, is_admin \\ false) when is_binary(user_name) do
    build_user_token(create_user(user_name, is_admin))
  end

end
