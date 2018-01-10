defmodule TrueBG.PingTest do
  use Cabbage.Feature, async: false, file: "ping.feature"
  import TrueBGWeb.Router.Helpers
  @endpoint TrueBGWeb.Endpoint

  # `setup_all/1` provides a callback for doing something before the entire suite runs
  # As below, `setup/1` provides means of doing something prior to each scenario
  setup do
    on_exit fn -> # Do something when the scenario is done
      IO.puts "Scenario completed, cleanup stuff"
    end
    %{my_starting: :state} # Return some beginning state
  end

  defwhen ~r/^you send me a ping$/, _params, state do
    %HTTPoison.Response{status_code: status_code, body: body} =
      HTTPoison.get!(
      ping_url(@endpoint, :ping))
    assert status_code == 200
    {:ok, Map.merge(state, %{body: body})}

  end

  defthen ~r/^I send you a pong$/, _params, state do
    assert state[:body] == "pong"
    {:ok, state}
  end

end
