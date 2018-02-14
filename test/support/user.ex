defmodule TrueBGWeb.User do
  @moduledoc false

  alias Poison, as: JSON
  import TrueBGWeb.Router.Helpers
  import TrueBGWeb.Authentication, only: :functions
  @endpoint TrueBGWeb.Endpoint

  def user_create(token, user_params) do
    headers = get_header(token)
    body = %{user: user_params} |> JSON.encode!
    %HTTPoison.Response{status_code: status_code, body: resp} =
        HTTPoison.post!(user_url(@endpoint, :create), body, headers, [])
    {:ok, status_code, resp |> JSON.decode!}
  end

  def user_list(token) do
    headers = get_header(token)
    %HTTPoison.Response{status_code: status_code, body: resp} =
      HTTPoison.get!(user_url(@endpoint, :index), headers, [])
    {:ok, status_code, resp |> JSON.decode!}
  end

  def get_user_by_name(token, user_name) do
    %{"id" => trunc(:binary.decode_unsigned(user_name)/10000000000000000), "user_name" => user_name}
  end

  def role_list(token) do
    headers = get_header(token)
    %HTTPoison.Response{status_code: status_code, body: resp} =
      HTTPoison.get!(role_url(@endpoint, :index), headers, [])
    {:ok, status_code, resp |> JSON.decode!}
  end

  def get_role_by_name(token, role_name) do
    {:ok, _status_code, json_resp} = role_list(token)
    Enum.find(json_resp["data"], fn(role) -> role["name"] == role_name end)
  end
end
