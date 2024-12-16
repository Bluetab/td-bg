defmodule TdBgWeb.Authentication do
  @moduledoc """
  This module defines the functions required to
  add auth headers to requests
  """
  import Plug.Conn

  alias TdBg.Auth.Claims
  alias TdBg.Auth.Guardian

  def put_auth_headers(conn, jwt) do
    conn
    |> put_req_header("content-type", "application/json")
    |> put_req_header("authorization", "Bearer #{jwt}")
  end

  def create_user_auth_conn(%{jwt: jwt, claims: claims}, conn) do
    conn = put_auth_headers(conn, jwt)

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
    |> authenticate()
  end

  def assign_permissions(context, nil), do: context

  def assign_permissions(context, permissions) do
    claims = Keyword.fetch!(context, :claims)
    %{id: domain_id} = domain = Keyword.get(context, :domain, CacheHelpers.insert_domain())
    CacheHelpers.put_session_permissions(claims, domain_id, permissions)

    context
    |> Keyword.put_new(:domain, domain)
    |> Keyword.put_new(:domain_id, domain_id)
  end

  defp authenticate(%{role: role} = claims) do
    {:ok, jwt, %{"jti" => jti, "exp" => exp} = full_claims} =
      Guardian.encode_and_sign(claims, %{role: role})

    {:ok, claims} = Guardian.resource_from_claims(full_claims)
    {:ok, _} = Guardian.decode_and_verify(jwt)
    TdCache.SessionCache.put(jti, exp)
    %{jwt: jwt, claims: claims}
  end
end
