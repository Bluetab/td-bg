defmodule TdBGWeb.EchoController do
  use TdBGWeb, :controller

  action_fallback TdBGWeb.FallbackController

  def echo(conn, params) do
    send_resp(conn, 200, params |> Poison.encode!)
  end
end
