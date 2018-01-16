defmodule TrueBG.AuthenticationTest do
  use Cabbage.Feature, async: false, file: "authentication.feature"
  import TrueBGWeb.Router.Helpers
  alias Poison, as: JSON
  @endpoint TrueBGWeb.Endpoint
  @headers {"Content-type", "application/json"}

  # `setup_all/1` provides a callback for doing something before the entire suite runs
  # As below, `setup/1` provides means of doing something prior to each scenario
  setup do
    on_exit fn -> # Do something when the scenario is done
      IO.puts "Scenario completed, cleanup stuff"
    end
    %{my_starting: :state} # Return some beginning state
  end

  defwhen ~r/^user "(?<user_name>[^"]+)" tries to log into the application with password "(?<user_passwd>[^"]+)"$/, %{user_name: user_name, user_passwd: user_passwd}, state do
    body = %{user: %{user_name: user_name, password: user_passwd}} |> JSON.encode!
    %HTTPoison.Response{status_code: status_code, body: body} =
      HTTPoison.post!(session_url(@endpoint, :create), body, [@headers], [])
    IO.puts "HOOLA"
    IO.inspect body
    assert status_code == 201
  end

  # defthen ~r/^the system returns a token with code "(?<status_code>[^"]+)"$/, %{status_code: status_code}, state do
  #   assert false, "Not implemented"
  # end

end
