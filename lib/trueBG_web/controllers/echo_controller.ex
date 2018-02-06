defmodule TrueBGWeb.PingController do
  use TrueBGWeb, :controller

  action_fallback TrueBGWeb.FallbackController

  def ping(conn, _params) do
    send_resp(conn, 200, "pong")
  end
end
