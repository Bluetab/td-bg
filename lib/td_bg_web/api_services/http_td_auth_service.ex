defmodule TdBgWeb.ApiServices.HttpTdAuthService do
  @moduledoc false

  alias Poison, as: JSON
  alias TdBg.Utils.CollectionUtils

  defp get_config do
    Application.get_env(:td_bg, :auth_service)
  end

  defp get_api_user_token do
    api_config = Application.get_env(:td_bg, :api_services_login)
    user_credentials = %{user_name: api_config[:user_name], password: api_config[:password]}
    body = %{user: user_credentials} |> JSON.encode!
    %HTTPoison.Response{status_code: _status_code, body: resp} =
      HTTPoison.post!(get_sessions_path(), body, ["Content-Type": "application/json", "Accept": "Application/json; Charset=utf-8"], [])
    resp = resp |> JSON.decode!
    resp["token"]
  end

  defp get_auth_endpoint do
    auth_service_config = get_config()
    "#{auth_service_config[:protocol]}://#{auth_service_config[:host]}:#{auth_service_config[:port]}"
  end

  defp get_users_path do
    auth_service_config = get_config()
    "#{get_auth_endpoint()}#{auth_service_config[:users_path]}"
  end

  defp get_sessions_path do
    auth_service_config = get_config()
    "#{get_auth_endpoint()}#{auth_service_config[:sessions_path]}"
  end

  def create(%{"user" => _user_params} = body) do
    headers = ["Accept": "Application/json; Charset=utf-8"]
    token = HTTPoison.post!(get_users_path(), body, headers, [])
    token
  end

  def search(%{"data" => %{"ids" => _ids}} = req) do
    token = get_api_user_token()

    headers = ["Authorization": "Bearer #{token}", "Content-Type": "application/json", "Accept": "Application/json; Charset=utf-8"]
    body = req |> JSON.encode!
    %HTTPoison.Response{status_code: _status_code, body: resp} = HTTPoison.post!("#{get_users_path()}/search", body, headers, [])
    json =
      resp
      |> JSON.decode!
      |> resp["data"]
    users = Enum.map(json, fn(user) -> %TdBg.Accounts.User{} |> Map.merge(CollectionUtils.to_struct(TdBg.Accounts.User, user)) end)
    users
  end

end
