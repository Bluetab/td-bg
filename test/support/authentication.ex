defmodule TdBgWeb.Authentication do
  @moduledoc """
  This module defines the functions required to
  add auth headers to requests
  """
  alias Phoenix.ConnTest
  alias TdBg.Accounts.Session
  alias TdBg.Auth.Guardian
  alias TdBg.Permissions.MockPermissionResolver
  alias TdBgWeb.ApiServices.MockTdAuthService

  import Plug.Conn

  @headers {"Content-type", "application/json"}

  def put_auth_headers(conn, jwt) do
    conn
    |> put_req_header("content-type", "application/json")
    |> put_req_header("authorization", "Bearer #{jwt}")
  end

  def create_user_auth_conn(%{role: role} = session) do
    {:ok, jwt, full_claims} = Guardian.encode_and_sign(session, %{role: role})
    register_token(jwt)
    conn = ConnTest.build_conn()
    conn = put_auth_headers(conn, jwt)
    {:ok, %{conn: conn, jwt: jwt, claims: full_claims}}
  end

  def get_header(token) do
    [@headers, {"authorization", "Bearer #{token}"}]
  end

  def create_session(user_name, opts \\ []) do
    role = Keyword.get(opts, :role, "user")

    MockTdAuthService.create_session(%{
      "user" => %{
        "user_name" => user_name,
        "role" => role
      }
    })
  end

  def find_or_create_user(user_name, opts \\ []) do
    user =
      case get_user_by_name(user_name) do
        nil ->
          role = Keyword.get(opts, :role, "user")

          MockTdAuthService.create_session(%{
            "user" => %{
              "user_name" => user_name,
              "role" => role
            }
          })

        user ->
          user
      end

    user
  end

  def get_user_by_name(user_name) do
    MockTdAuthService.get_user_by_name(user_name)
  end

  def get_users do
    MockTdAuthService.index()
  end

  def build_user_token(%Session{role: role} = session) do
    case Guardian.encode_and_sign(session, %{role: role}) do
      {:ok, jwt, _full_claims} -> register_token(jwt)
      _ -> raise "Problems encoding and signing a session"
    end
  end

  def build_user_token(user_name, opts \\ []) when is_binary(user_name) do
    user = find_or_create_user(user_name, opts)
    build_user_token(user)
  end

  def get_user_token(user_name) do
    user_name
    |> build_user_token(role_opts(user_name))
    |> register_token
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
