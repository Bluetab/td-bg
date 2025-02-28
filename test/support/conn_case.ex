defmodule TdBgWeb.ConnCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require setting up a connection.

  Such tests rely on `Phoenix.ConnTest` and also
  import other functionality to make it easier
  to build common datastructures and query the data layer.

  Finally, if the test case interacts with the database,
  it cannot be async. For this reason, every test runs
  inside a transaction which is reset at the beginning
  of the test unless the test case is marked as async.
  """

  use ExUnit.CaseTemplate

  alias Ecto.Adapters.SQL.Sandbox
  alias Phoenix.ConnTest
  alias TdBgWeb.Authentication

  using do
    quote do
      # Import conveniences for testing with connections
      import Assertions
      import CacheHelpers, only: [put_session_permissions: 2, put_session_permissions: 3]
      import Plug.Conn
      import Phoenix.ConnTest
      import TdBg.Factory

      alias TdBgWeb.Router.Helpers, as: Routes

      # The default endpoint for testing
      @endpoint TdBgWeb.Endpoint
    end
  end

  setup tags do
    :ok = Sandbox.checkout(TdBg.Repo)

    unless tags[:async] do
      Sandbox.mode(TdBg.Repo, {:shared, self()})
      parent = self()
      allow(parent, [TdBg.Cache.ConceptLoader, TdCore.Search.IndexWorker])
    end

    locale = tags[:locale] || "en"

    conn =
      ConnTest.build_conn()
      |> Plug.Conn.assign(:locale, locale)

    case tags[:authentication] do
      nil ->
        [conn: conn]

      auth_opts ->
        auth_opts
        |> Authentication.create_claims()
        |> Authentication.create_user_auth_conn(conn)
        |> Authentication.assign_permissions(auth_opts[:permissions])
    end
  end

  defp allow(parent, workers) do
    Enum.each(workers, fn worker ->
      case Process.whereis(worker) do
        nil -> nil
        pid -> Sandbox.allow(TdBg.Repo, parent, pid)
      end
    end)
  end
end
