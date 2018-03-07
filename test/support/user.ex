defmodule TdBGWeb.User do
  @moduledoc false

  alias Poison, as: JSON
  import TdBGWeb.Router.Helpers
  import TdBGWeb.Authentication, only: :functions
  @endpoint TdBGWeb.Endpoint

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
