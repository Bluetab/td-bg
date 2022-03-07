defmodule TdBg.Application do
  @moduledoc false

  use Application

  alias TdBgWeb.Endpoint

  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    env = Application.get_env(:td_bg, :env)

    # Define workers and child supervisors to be supervised
    children =
      [
        # Start the Ecto repository
        TdBg.Repo,
        # Start the endpoint when the application starts
        TdBgWeb.Endpoint
      ] ++ workers(env)

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: TdBg.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    Endpoint.config_change(changed, removed)
    :ok
  end

  defp workers(:test), do: []

  defp workers(_env) do
    [
      # Elasticsearch worker
      TdBg.Search.Cluster,
      # Worker for background indexing
      TdBg.Search.IndexWorker,
      # Cache workers
      TdBg.Cache.ConceptLoader,
      TdBg.Cache.DomainLoader,
      TdBg.Scheduler
    ]
  end
end
