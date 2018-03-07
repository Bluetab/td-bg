defmodule TdBGWeb.UserController do
  use TdBGWeb, :controller

  action_fallback TdBGWeb.FallbackController

  @td_auth_api Application.get_env(:td_bg, :auth_service)[:api_service]

  def create(_conn, %{"user" => _user_params} = req) do
    @td_auth_api.create(req)
  end

  def search(_conn, %{"data" => %{"ids" => _ids}} = req) do
    @td_auth_api.search(req)
  end

end
