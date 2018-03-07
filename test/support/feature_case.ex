defmodule TdBGWeb.FeatureCase do
  @moduledoc """
  This module defines the test case to be used by
  feature tests.

  """

  use ExUnit.CaseTemplate
  alias Ecto.Adapters.SQL.Sandbox

  using do
    quote do
      import TdBGWeb.Router.Helpers
      @endpoint TdBGWeb.Endpoint
    end
  end

  setup tags do
    :ok = Sandbox.checkout(TdBG.Repo)
    unless tags[:async] do
      Sandbox.mode(TdBG.Repo, {:shared, self()})
    end
    :ok
  end
end
