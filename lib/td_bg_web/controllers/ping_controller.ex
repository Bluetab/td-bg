defmodule TdBgWeb.EchoController do
  use TdBgWeb, :controller

  action_fallback TdBgWeb.FallbackController

  def echo(conn, params) do
    send_resp(conn, 200, params |> Poison.encode!)
  end
end
