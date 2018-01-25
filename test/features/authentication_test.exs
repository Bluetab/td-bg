defmodule TrueBG.AuthenticationTest do
  use Cabbage.Feature, async: false, file: "authentication.feature"
  use TrueBGWeb.ConnCase
  import TrueBGWeb.Router.Helpers
  import TrueBGWeb.ResponseCode
  alias TrueBG.Accounts
  alias Poison, as: JSON
  @endpoint TrueBGWeb.Endpoint
  @headers {"Content-type", "application/json"}

  # Scenario: logging

  defwhen ~r/^user "(?<user_name>[^"]+)" tries to log into the application with password "(?<user_passwd>[^"]+)"$/, %{user_name: user_name, user_passwd: user_passwd}, state do
    {_, status_code, json_resp} = session_create(user_name, user_passwd)
    {:ok, Map.merge(state, %{status_code: status_code, resp: json_resp})}
  end

  defthen ~r/^the system returns a token with code "(?<status_code>[^"]+)"$/, %{status_code: status_code}, state do
    assert status_code == to_response_code(state[:status_code])
    json_resp = state[:resp]
    assert json_resp["token"] != nil
  end

  defthen ~r/^the system returns a result with code "(?<status_code>[^"]+)"$/, %{status_code: status_code}, state do
    assert status_code == to_response_code(state[:status_code])
  end

  # Scenario: logging error

  defgiven ~r/^user "(?<user_name>[^"]+)" is logged in the application with password "(?<password>[^"]+)"$/, %{user_name: user_name, password: password}, state do
    {_, status_code, json_resp} = session_create(user_name, password)
    assert rc_created() == to_response_code(status_code)
    {:ok, Map.merge(state, %{status_code: status_code, resp: json_resp})}
  end

  defwhen ~r/^"(?<user_name>[^"]+)" tries to create a user "(?<new_user_name>[^"]+)" with password "(?<new_password>[^"]+)"$/, %{user_name: _user_name, new_user_name: new_user_name, new_password: new_password}, state do
    {_, status_code, json_resp} = user_create(state[:resp]["token"], new_user_name, new_password)
    {:ok, Map.merge(state, %{status_code: status_code, resp: json_resp})}
  end

  defand ~r/^user "(?<new_user_name>[^"]+)" can be authenticated with password "(?<new_password>[^"]+)"$/, %{new_user_name: new_user_name, new_password: new_password}, _state do
    {_, status_code, json_resp} = session_create(new_user_name, new_password)
      assert rc_created() == to_response_code(status_code)
      assert json_resp["token"] != nil
  end

  # Scenario: logging error for non existing user

  defwhen ~r/^"johndoe" tries to modify his password with following data:$/,
          %{table: [%{old_password: old_password, new_password: new_password}]}, state do
      {_, status_code} = session_change_password(state[:token], old_password, new_password)
      {:ok, Map.merge(state, %{status_code: status_code})}
  end

  # Scenario: Error when creating a new user in the application by a non admin user

  defgiven ~r/^an existing user "(?<user_name>[^"]+)" with password "(?<password>[^"]+)" without "super-admin" permission$/, %{user_name: user_name, password: password}, state do
    user = Accounts.get_user_by_name(user_name)
    unless user do
      Accounts.create_user(%{user_name: user_name, password: password})
    end
    {:ok, state}
  end

  defand ~r/^user "(?<user_name>[^"]+)" is logged in the application with password "(?<password>[^"]+)"$/, %{user_name: user_name, password: password}, state do
    {_, status_code, json_resp} = session_create(user_name, password)
    assert rc_created() == to_response_code(status_code)
    {:ok, Map.merge(state, %{status_code: status_code, token: json_resp["token"], resp: json_resp})}
  end

  defand ~r/^user "(?<user_name>[^"]+)" can not be authenticated with password "(?<password>[^"]+)"$/, %{user_name: user_name, password: password}, _state do
    {_, status_code, json_resp} = session_create(user_name, password)
    assert rc_forbidden() == to_response_code(status_code)
    assert json_resp["token"] == nil
  end

  # Scenario: Error when creating a duplicated user

  defgiven ~r/^an existing user "(?<user_name>[^"]+)" with password "(?<password>[^"]+)" with "super-admin" permission$/, %{user_name: user_name, password: password}, state do
    create_user(user_name, password, true)
    {:ok, state}
  end

  # Scenario: Password modification

  # Scenario: Password modification error

  # Scenario: Loggout

  defgiven ~r/^Given an existing user "(?<user_name>[^"]+)" with password "(?<password>[^"]+)" without "super-admin" permission$/, %{user_name: user_name, password: password}, state do
    user = create_user(user_name, password, false)
    {:ok, state}
  end

  defwhen ~r/^"johndoe" signs out of the application$/, %{}, state do
    {_, status_code} = session_destroy(state[:token])
    {:ok, Map.merge(state, %{status_code: status_code})}
  end

  defand ~r/^user "johndoe" gets a "Forbidden" code when he pings the application$/, %{}, state do
    {_, status_code} = ping(state[:token])
    assert rc_forbidden() == to_response_code(status_code)
  end

  defp create_user(user_name, password, is_admin) do
    found = Accounts.get_user_by_name(user_name)
    if found, do: found, else: Accounts.create_user(%{user_name: user_name, password: password, is_admin: is_admin})
  end

  defp ping(token) do
    headers = [@headers, {"authorization", "Bearer #{token}"}]
    %HTTPoison.Response{status_code: status_code, body: _resp} =
      HTTPoison.get!(session_url(@endpoint, :ping), headers)
    {:ok, status_code}
  end

  defp session_create(user_name, user_password) do
    body = %{user: %{user_name: user_name, password: user_password}} |> JSON.encode!
    %HTTPoison.Response{status_code: status_code, body: resp} =
        HTTPoison.post!(session_url(@endpoint, :create), body, [@headers], [])
    {:ok, status_code, resp |> JSON.decode!}
  end

  defp session_destroy(token) do
    headers = [@headers, {"authorization", "Bearer #{token}"}]
    %HTTPoison.Response{status_code: status_code, body: _resp} =
        HTTPoison.delete!(session_url(@endpoint, :destroy), headers, [])
    {:ok, status_code}
  end

  defp session_change_password(token, old_password, new_password) do
    headers = [@headers, {"authorization", "Bearer #{token}"}]
    body = %{old_passord: old_password, new_password: new_password} |> JSON.encode!
    %HTTPoison.Response{status_code: status_code, body: _resp} =
      HTTPoison.put!(session_url(@endpoint, :change_password), body, headers, [])
      {:ok, status_code}
  end

  defp user_create(token, user_name, password) do
    headers = [@headers, {"authorization", "Bearer #{token}"}]
    body = %{user: %{user_name: user_name, password: password}} |> JSON.encode!
    %HTTPoison.Response{status_code: status_code, body: resp} =
        HTTPoison.post!(user_url(@endpoint, :create), body, headers, [])
    {:ok, status_code, resp |> JSON.decode!}
  end
end
