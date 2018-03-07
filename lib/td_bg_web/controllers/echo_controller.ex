defmodule TdBGWeb.PingController do
  use TdBGWeb, :controller

  action_fallback TdBGWeb.FallbackController

  def ping(conn, _params) do
    send_resp(conn, 200, "pong")
  end
end
