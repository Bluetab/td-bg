defmodule TdBgWeb.Authentication do
  @moduledoc """
  This module defines the functions required to
  add auth headers to requests
  """
  import Plug.Conn

  alias Phoenix.ConnTest
  alias TdBg.Auth.Claims
  alias TdBg.Auth.Guardian
  alias TdBg.Permissions.MockPermissionResolver

  @headers {"Content-type", "application/json"}

  def put_auth_headers(conn, jwt) do
    conn
    |> put_req_header("content-type", "application/json")
    |> put_req_header("authorization", "Bearer #{jwt}")
  end

  def create_user_auth_conn(%{role: role} = claims) do
    {:ok, jwt, full_claims} = Guardian.encode_and_sign(claims, %{role: role})
    {:ok, claims} = Guardian.resource_from_claims(full_claims)
    register_token(jwt)

    conn =
      ConnTest.build_conn()
      |> put_auth_headers(jwt)

    {:ok, %{conn: conn, jwt: jwt, claims: claims}}
  end

  def get_header(token) do
    [@headers, {"authorization", "Bearer #{token}"}]
  end

  def create_claims(user_name, opts \\ []) do
    role = Keyword.get(opts, :role, "user")
    is_admin = role === "admin"

    %Claims{
      user_id: Integer.mod(:binary.decode_unsigned(user_name), 100_000),
      user_name: user_name,
      role: role,
      is_admin: is_admin
    }
  end

  def build_user_token(%Claims{role: role} = claims) do
    case Guardian.encode_and_sign(claims, %{role: role}) do
      {:ok, jwt, _full_claims} -> register_token(jwt)
      _ -> raise "Problems encoding and signing a claims"
    end
  end

  def build_user_token(user_name, opts \\ []) when is_binary(user_name) do
    opts = user_name |> role_opts() |> Keyword.merge(opts)

    user_name
    |> create_claims(opts)
    |> build_user_token()
  end

  def get_user_token(user_name) do
    opts = role_opts(user_name)

    user_name
    |> build_user_token(opts)
    |> register_token()
  end

  defp role_opts("app-admin"), do: [role: "admin"]
  defp role_opts(_user_name), do: []

  defp register_token(token) do
    case Guardian.decode_and_verify(token) do
      {:ok, resource} -> MockPermissionResolver.register_token(resource)
      _ -> raise "Problems decoding and verifying token"
    end

    token
  end
end
