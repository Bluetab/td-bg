defmodule TrueBGWeb.GlobalFeatures do
  @moduledoc false
  use Cabbage.Feature

  defthen ~r/^the system returns a result with code (?<status_code>[^"]+)$/,
          %{status_code: status_code}, %{status_code: http_status_code} = state do
    assert status_code == to_response_code(http_status_code)
    {:ok, Map.merge(state, %{})}
  end

end
