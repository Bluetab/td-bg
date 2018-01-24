defmodule TrueBGWeb.Authentication do
  @moduledoc """
  This module defines the functions required to
  add auth headers to requests
  """
  import Plug.Conn
  alias Phoenix.ConnTest
  alias TrueBG.Auth.Guardian

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

end
