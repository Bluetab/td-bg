defmodule TrueBGWeb.Authentication do
  @moduledoc """
  This module defines the functions required to
  add auth headers to requests
  """
  alias Phoenix.ConnTest
  alias TrueBG.Auth.Guardian
  alias Poison, as: JSON
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

  def session_create(user_name, user_password) do
    body = %{user: %{user_name: user_name, password: user_password}} |> JSON.encode!
    %HTTPoison.Response{status_code: status_code, body: resp} =
        HTTPoison.post!(session_url(@endpoint, :create), body, [@headers], [])
    {:ok, status_code, resp |> JSON.decode!}
  end

  def session_destroy(token) do
    headers = get_header(token)
    %HTTPoison.Response{status_code: status_code, body: _resp} =
        HTTPoison.delete!(session_url(@endpoint, :destroy), headers, [])
    {:ok, status_code}
  end

  def session_change_password(token, old_password, new_password) do
    headers = get_header(token)
    body = %{old_passord: old_password, new_password: new_password} |> JSON.encode!
    %HTTPoison.Response{status_code: status_code, body: _resp} =
      HTTPoison.put!(session_url(@endpoint, :change_password), body, headers, [])
      {:ok, status_code}
  end
end
