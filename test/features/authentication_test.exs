defmodule TrueBG.AuthenticationTest do
  use Cabbage.Feature, async: false, file: "authentication.feature"
  use TrueBGWeb.ConnCase
  import TrueBGWeb.Router.Helpers
  alias Poison, as: JSON
  @endpoint TrueBGWeb.Endpoint
  @headers {"Content-type", "application/json"}

  defwhen ~r/^user "(?<user_name>[^"]+)" tries to log into the application with password "(?<user_passwd>[^"]+)"$/, %{user_name: user_name, user_passwd: user_passwd}, state do
    body = %{user:
             %{user_name: user_name, password: user_passwd}} |> JSON.encode!
    %HTTPoison.Response{status_code: status_code, body: resp} =
      HTTPoison.post!(session_url(@endpoint, :create), body, [@headers], [])
      jsonResp = (resp |> JSON.decode!)
     {:ok, Map.merge(state, %{status_code: status_code, resp: jsonResp })}
  end

  defthen ~r/^the system returns a token with code "(?<status_code>[^"]+)"$/, %{status_code: status_code}, state do
    assert status_code == get_status(state[:status_code])
    jsonR = state[:resp]
    assert jsonR["token"] != nil
  end

  defthen ~r/^the system returns a result with code "(?<status_code>[^"]+)"$/, %{status_code: status_code}, state do
    assert status_code == get_status(state[:status_code])
  end

  defp get_status(status_code) do
    case status_code do
      201 -> "Created"
      401 -> "Forbidden"
      _ -> "Unknown"
    end
  end
end
