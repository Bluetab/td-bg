defmodule TrueBGWeb.ApiServices.HttpTdAuthService do
  @moduledoc false

  defp get_auth_endpoint do
    auth_service_config = Application.get_env(:trueBG, :auth_service)
    "#{auth_service_config.protocol}/#{auth_service_config.host}:#{auth_service_config.port}"
  end

  defp get_users_path do
    auth_service_config = Application.get_env(:trueBG, :auth_service)
    "#{get_auth_endpoint}#{auth_service_config.users_path}"
  end

  defp get_sessions_path do
    auth_service_config = Application.get_env(:trueBG, :auth_service)
    "#{get_auth_endpoint}#{auth_service_config.sessions_path}"
  end

  def create(%{"user" => _user_params} = body) do
    headers = ["Accept": "Application/json; Charset=utf-8"]
    token = HTTPoison.post!(get_users_path, body, headers, [])
  end

  def search(%{"data" => %{"ids" => _ids}} = body) do
    token = HTTPoison.post!(get_sessions_path, body, ["Content-Type": "application/json", "Accept": "Application/json; Charset=utf-8"], [])
    headers = ["Authorization": "Bearer #{token}", "Content-Type": "application/json", "Accept": "Application/json; Charset=utf-8"]

    HTTPoison.post!(get_users_path, body, headers, [])
  end

end
