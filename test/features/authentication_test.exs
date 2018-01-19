defmodule TrueBG.AuthenticationTest do
  use Cabbage.Feature, async: false, file: "authentication.feature"
  use TrueBGWeb.ConnCase
  import TrueBGWeb.Router.Helpers
  alias Poison, as: JSON
  @endpoint TrueBGWeb.Endpoint
  @headers {"Content-type", "application/json"}

  # Scenario: logging

  defwhen ~r/^user "(?<user_name>[^"]+)" tries to log into the application with password "(?<user_passwd>[^"]+)"$/, %{user_name: user_name, user_passwd: user_passwd}, state do
    {_, status_code, jsonResp} = session_create(user_name, user_passwd)
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

  # Scenario: logging error

  defgiven ~r/^user "(?<user_name>[^"]+)" is logged in the application$/, %{user_name: user_name}, state do
    {_, status_code, jsonResp} = session_create(user_name, "mypass")
    assert "Created" == get_status(status_code)
    {:ok, Map.merge(state, %{status_code: status_code, resp: jsonResp })}
  end

  defwhen ~r/^"(?<user_name>[^"]+)" tries to create a user "(?<new_user_name>[^"]+)" with password "(?<new_password>[^"]+)"$/, %{user_name: _user_name, new_user_name: new_user_name, new_password: new_password}, state do
    {_, status_code, jsonResp} = user_create(state[:resp]["token"], new_user_name, new_password)
    {:ok, Map.merge(state, %{status_code: status_code, resp: jsonResp })}
  end

  defand ~r/^user "(?<new_user_name>[^"]+)" can be authenticated with password "(?<new_password>[^"]+)"$/, %{new_user_name: new_user_name, new_password: new_password}, _state do
    {_, status_code, jsonResp} = session_create(new_user_name, new_password)
      assert "Created" == get_status(status_code)
      assert jsonResp["token"] != nil
  end

  # Scenario: logging error for non existing user

  # Scenario: Error when creating a new user in the application by a non admin user

  defgiven ~r/^an existing user "(?<nobody>[^"]+)" with password "(?<mypass>[^"]+)" without "(?<super_admin>[^"]+)" permission$/, %{nobody: nobody, mypass: mypass, super_admin: super_admin}, state do

  end

  defand ~r/^user "(?<newuser>[^"]+)" can not be authenticated with password "(?<newpass>[^"]+)"$/, %{newuser: newuser, newpass: newpass}, state do

  end

  defp session_create(user_name, user_password) do
    body = %{user: %{user_name: user_name, password: user_password}} |> JSON.encode!
    %HTTPoison.Response{status_code: status_code, body: resp} =
        HTTPoison.post!(session_url(@endpoint, :create), body, [@headers], [])
    {:ok, status_code, resp |> JSON.decode!}
  end

  defp user_create(token, user_name, password) do
    headers = [@headers ,{"authorization", "Bearer #{token}"}]
    body = %{user: %{user_name: user_name, password: password}} |> JSON.encode!
    %HTTPoison.Response{status_code: status_code, body: resp} =
        HTTPoison.post!(user_url(@endpoint, :create), body, headers, [])
    {:ok, status_code, resp |> JSON.decode!}
  end

  defp get_status(status_code) do
    case status_code do
      201 -> "Created"
      401 -> "Forbidden"
      _ -> "Unknown"
    end
  end
end
