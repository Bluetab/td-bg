defmodule TrueBGWeb.Authentication do
  @moduledoc """
  This module defines the functions required to
  add auth headers to requests
  """
  import Plug.Conn
  import Phoenix.ConnTest, only: :functions

  def put_auth_headers(conn, jwt) do
    conn
    |> put_req_header("content-type", "application/json")
    |> put_req_header("authorization", "Bearer #{jwt}")
  end

  def recycle_and_set_headers(conn, jwt) do
    conn
    |> recycle()
    |> put_auth_headers(jwt)
  end

end
