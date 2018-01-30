defmodule TrueBGWeb.User do

  alias Poison, as: JSON
  import TrueBGWeb.Router.Helpers
  @endpoint TrueBGWeb.Endpoint
  @headers {"Content-type", "application/json"}

  def user_create(token, user_params) do
    headers = [@headers, {"authorization", "Bearer #{token}"}]
    body = %{user: user_params} |> JSON.encode!
    %HTTPoison.Response{status_code: status_code, body: resp} =
        HTTPoison.post!(user_url(@endpoint, :create), body, headers, [])
    {:ok, status_code, resp |> JSON.decode!}
  end
end
