defmodule TdBgWeb.Authentication do
  @moduledoc """
  This module defines the functions required to
  add auth headers to requests
  """
  import Plug.Conn

  alias Phoenix.ConnTest
  alias TdBg.Auth.Claims
  alias TdBg.Auth.Guardian

  def put_auth_headers(conn, jwt) do
    conn
    |> put_req_header("content-type", "application/json")
    |> put_req_header("authorization", "Bearer #{jwt}")
  end

  def create_user_auth_conn(%{role: role} = claims) do
    {:ok, jwt, full_claims} = Guardian.encode_and_sign(claims, %{role: role})
    {:ok, claims} = Guardian.resource_from_claims(full_claims)

    conn =
      ConnTest.build_conn()
      |> put_auth_headers(jwt)

    [conn: conn, jwt: jwt, claims: claims]
  end

  def get_header(token) do
    [{"content-type", "application/json"}, {"authorization", "Bearer #{token}"}]
  end

  def create_claims(opts \\ []) do
    role = Keyword.get(opts, :role, "user")

    user_name =
      case Keyword.get(opts, :user_name) do
        nil -> if role === "admin", do: "app-admin", else: "user"
        name -> name
      end

    %Claims{
      user_id: Integer.mod(:binary.decode_unsigned(user_name), 100_000),
      user_name: user_name,
      role: role
    }
  end
end
