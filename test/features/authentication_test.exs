defmodule TrueBG.AuthenticationTest do
  use Cabbage.Feature, async: false, file: "authentication.feature"
  use TrueBGWeb.ConnCase
  import TrueBGWeb.Router.Helpers
  alias Poison, as: JSON
  @endpoint TrueBGWeb.Endpoint
  @headers {"Content-type", "application/json"}

  defwhen ~r/^user "(?<user_name>[^"]+)" tries to log into the application with password "(?<user_passwd>[^"]+)"$/, %{user_name: user_name, user_passwd: user_passwd}, _state do
    body = %{user:
             %{user_name: user_name, password: user_passwd}} |> JSON.encode!
    %HTTPoison.Response{status_code: status_code, body: _body} =
      HTTPoison.post!(session_url(@endpoint, :create), body, [@headers], [])
    assert status_code == 201
  end

  # defthen ~r/^the system returns a token with code "(?<status_code>[^"]+)"$/, %{status_code: status_code}, state do
  #   assert false, "Not implemented"
  # end

end
