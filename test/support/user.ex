defmodule TdBgWeb.User do
  @moduledoc false

  alias Poison, as: JSON
  import TdBgWeb.Router.Helpers
  import TdBgWeb.Authentication, only: :functions
  @endpoint TdBgWeb.Endpoint
  @td_auth_api Application.get_env(:td_bg, :auth_service)[:api_service]

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

  def is_admin_bool(is_admin) do
    case is_admin do
      "yes" -> true
      "no" -> false
      _ -> is_admin
    end
  end

  def get_group_by_name(group_name) do
    @td_auth_api.get_group_by_name(group_name)
  end
end
