defmodule TrueBGWeb.EchoController do
  use TrueBGWeb, :controller

  action_fallback TrueBGWeb.FallbackController

  def echo(conn, params) do
    send_resp(conn, 200, params |> Poison.encode!)
  end
end
