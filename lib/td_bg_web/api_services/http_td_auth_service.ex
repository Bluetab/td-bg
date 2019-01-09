defmodule TdBgWeb.ApiServices.HttpTdAuthService do
  @moduledoc false

  alias Poison, as: JSON
  alias TdBg.Accounts.Group
  alias TdBg.Accounts.User
  alias TdBg.Utils.CollectionUtils

  defp get_config do
    Application.get_env(:td_bg, :auth_service)
  end

  defp get_api_user_token do
    api_config = Application.get_env(:td_bg, :api_services_login)

    user_credentials = %{
      user_name: api_config[:api_username],
      password: api_config[:api_password]
    }

    body = %{user: user_credentials} |> JSON.encode!()

    %HTTPoison.Response{status_code: _status_code, body: resp} =
      HTTPoison.post!(
        get_sessions_path(),
        body,
        ["Content-Type": "application/json", Accept: "Application/json; Charset=utf-8"],
        []
      )

    resp = resp |> JSON.decode!()
    resp["token"]
  end

  defp get_auth_endpoint do
    auth_service_config = get_config()

    "#{auth_service_config[:protocol]}://#{auth_service_config[:auth_host]}:#{
      auth_service_config[:auth_port]
    }"
  end

  defp get_users_path do
    auth_service_config = get_config()
    "#{get_auth_endpoint()}#{auth_service_config[:users_path]}"
  end

  defp get_sessions_path do
    auth_service_config = get_config()
    "#{get_auth_endpoint()}#{auth_service_config[:sessions_path]}"
  end

  defp get_groups_path do
    auth_service_config = get_config()
    "#{get_auth_endpoint()}#{auth_service_config[:groups_path]}"
  end

  def create(%{"user" => _user_params} = body) do
    headers = [Accept: "Application/json; Charset=utf-8"]
    token = HTTPoison.post!(get_users_path(), body, headers, [])
    token
  end

  def create_user(%{"user" => user_params} = req) do
    token = get_api_user_token()

    headers = [
      Authorization: "Bearer #{token}",
      "Content-Type": "application/json",
      Accept: "Application/json; Charset=utf-8"
    ]

    # search user
    body =
      %{"data" => %{"user_name" => user_params.user_name}}
      |> JSON.encode!()

    %HTTPoison.Response{status_code: _status_code, body: resp} =
      HTTPoison.post!("#{get_users_path()}search", body, headers, [])

    json_user =
      resp
      |> JSON.decode!()

    json_user = json_user["data"]

    if json_user do
      user = %User{} |> Map.merge(CollectionUtils.to_struct(User, json_user))
      user
    else
      body = req |> JSON.encode!()

      %HTTPoison.Response{status_code: _status_code, body: resp} =
        HTTPoison.post!("#{get_users_path()}", body, headers, [])

      json_user =
        resp
        |> JSON.decode!()

      json_user = json_user["data"]
      user = %User{} |> Map.merge(CollectionUtils.to_struct(User, json_user))
      user
    end
  end

  def index do
    token = get_api_user_token()

    headers = [
      Authorization: "Bearer #{token}",
      "Content-Type": "application/json",
      Accept: "Application/json; Charset=utf-8"
    ]

    %HTTPoison.Response{status_code: _status_code, body: resp} =
      HTTPoison.get!("#{get_users_path()}", headers, [])

    json =
      resp
      |> JSON.decode!()

    json = json["data"]

    users =
      Enum.map(json, fn user -> %User{} |> Map.merge(CollectionUtils.to_struct(User, user)) end)

    users
  end

  def search_users(%{"ids" => []}), do: []

  def search_users(%{"ids" => _ids} = ids) do
    token = get_api_user_token()

    headers = [
      Authorization: "Bearer #{token}",
      "Content-Type": "application/json",
      Accept: "Application/json; Charset=utf-8"
    ]

    req = %{"data" => ids}
    body = req |> JSON.encode!()

    %HTTPoison.Response{status_code: _status_code, body: resp} =
      HTTPoison.post!("#{get_users_path()}/search", body, headers, [])

    json =
      resp
      |> JSON.decode!()

    json = json["data"]

    users =
      Enum.map(json, fn user -> %User{} |> Map.merge(CollectionUtils.to_struct(User, user)) end)

    users
  end

  def get_user(id) do
    token = get_api_user_token()

    headers = [
      Authorization: "Bearer #{token}",
      "Content-Type": "application/json",
      Accept: "Application/json; Charset=utf-8"
    ]

    %HTTPoison.Response{status_code: status_code, body: resp} =
      HTTPoison.get!("#{get_users_path()}/#{id}", headers, [])

    case status_code do
      200 ->
        json_user = resp |> JSON.decode!()
        json_user = json_user["data"]
        %User{} |> Map.merge(CollectionUtils.to_struct(User, json_user))

      _ ->
        nil
    end
  end

  def create_group(%{"group" => _group_params} = req) do
    token = get_api_user_token()

    headers = [
      Authorization: "Bearer #{token}",
      "Content-Type": "application/json",
      Accept: "Application/json; Charset=utf-8"
    ]

    body = req |> JSON.encode!()

    %HTTPoison.Response{status_code: _status_code, body: resp} =
      HTTPoison.post!("#{get_groups_path()}", body, headers, [])

    json_group =
      resp
      |> JSON.decode!()

    json_group = json_group["data"]
    group = %Group{} |> Map.merge(CollectionUtils.to_struct(Group, json_group))
    group
  end
end
