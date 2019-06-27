defmodule TdBgWeb.FeatureCase do
  @moduledoc """
  This module defines the test case to be used by
  feature tests.

  """

  use ExUnit.CaseTemplate
  alias Ecto.Adapters.SQL.Sandbox

  using do
    quote do
      alias TdBgWeb.Router.Helpers, as: Routes
      @endpoint TdBgWeb.Endpoint
    end
  end

  setup tags do
    :ok = Sandbox.checkout(TdBg.Repo)

    unless tags[:async] do
      Sandbox.mode(TdBg.Repo, {:shared, self()})
      parent = self()

      case Process.whereis(TdBg.Cache.ConceptLoader) do
        nil -> nil
        pid -> Sandbox.allow(TdBg.Repo, parent, pid)
      end

      case Process.whereis(TdBg.Cache.DomainLoader) do
        nil -> nil
        pid -> Sandbox.allow(TdBg.Repo, parent, pid)
      end
    end

    :ok
  end
end
