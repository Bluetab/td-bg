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
      import Plug.Conn
      import Phoenix.ConnTest
      import TdBg.Factory
      import TdBgWeb.Authentication, only: [create_acl_entry: 4, create_claims: 1]

      alias TdBgWeb.Router.Helpers, as: Routes

      # The default endpoint for testing
      @endpoint TdBgWeb.Endpoint
    end
  end

  setup tags do
    start_supervised!(MockPermissionResolver)

    :ok = Sandbox.checkout(TdBg.Repo)

    unless tags[:async] do
      Sandbox.mode(TdBg.Repo, {:shared, self()})
      parent = self()
      allow(parent, [TdBg.Cache.ConceptLoader, TdBg.Search.IndexWorker])
    end

    case tags[:authentication] do
      nil ->
        [conn: ConnTest.build_conn()]

      auth_opts ->
        auth_opts
        |> Authentication.create_claims()
        |> Authentication.create_user_auth_conn()
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
