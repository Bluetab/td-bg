defmodule TrueBGWeb.FeatureCase do
  @moduledoc """
  This module defines the test case to be used by
  feature tests.

  """

  use ExUnit.CaseTemplate
  alias Ecto.Adapters.SQL.Sandbox

  using do
    quote do
      import TrueBGWeb.Router.Helpers
      @endpoint TrueBGWeb.Endpoint
    end
  end

  setup tags do
    :ok = Sandbox.checkout(TrueBG.Repo)
    unless tags[:async] do
      Sandbox.mode(TrueBG.Repo, {:shared, self()})
    end
    :ok
  end
end
