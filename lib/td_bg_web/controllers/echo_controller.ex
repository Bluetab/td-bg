defmodule TdBgWeb.PingController do
  use TdBgWeb, :controller

  action_fallback TdBgWeb.FallbackController

  def ping(conn, _params) do
    send_resp(conn, 200, "pong")
  end
end
