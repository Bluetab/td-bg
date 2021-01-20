defmodule TdBgWeb.Authentication do
  @moduledoc """
  This module defines the functions required to
  add auth headers to requests
  """
  import Plug.Conn

  alias Phoenix.ConnTest
  alias TdBg.Auth.Claims
  alias TdBg.Auth.Guardian

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

  def build_user_token(%Claims{role: role} = claims) do
    case Guardian.encode_and_sign(claims, %{role: role}) do
      {:ok, jwt, _full_claims} -> register_token(jwt)
      _ -> raise "Problems encoding and signing a claims"
    end
  end

  def build_user_token(opts) when is_list(opts) do
    opts
    |> create_claims()
    |> build_user_token()
  end

  def build_user_token(user_name) when is_binary(user_name) do
    user_name
    |> role_opts()
    |> build_user_token()
  end

  defp role_opts("app-admin"), do: [user_name: "app-admin", role: "admin"]
  defp role_opts(user_name), do: [user_name: user_name, role: "user"]

  defp register_token(token) do
    case Guardian.decode_and_verify(token) do
      {:ok, resource} -> MockPermissionResolver.register_token(resource)
      _ -> raise "Problems decoding and verifying token"
    end

    token
  end

  def create_acl_entry(user_id, resource_type, resource_id, role_name)
      when is_binary(role_name) do
    MockPermissionResolver.create_acl_entry(%{
      principal_type: "user",
      principal_id: user_id,
      resource_type: resource_type,
      resource_id: resource_id,
      role_name: role_name
    })
  end
end
