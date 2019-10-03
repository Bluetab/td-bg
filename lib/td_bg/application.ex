defmodule TdBg.Application do
  @moduledoc false
  use Application
  alias TdBg.Metrics.PrometheusExporter
  alias TdBgWeb.Endpoint

  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec

    env = Application.get_env(:td_dd, :env)

    metrics_worker = %{
      id: TdBg.Metrics.BusinessConcepts,
      start: {TdBg.Metrics.BusinessConcepts, :start_link, []}
    }

    # Define workers and child supervisors to be supervised
    children =
      [
        # Start the Ecto repository
        supervisor(TdBg.Repo, []),
        # Start the endpoint when the application starts
        supervisor(TdBgWeb.Endpoint, []),
        # Elasticsearch worker
        TdBg.Search.Cluster,
        # Worker for background indexing
        worker(TdBg.Search.IndexWorker, [TdBg.Search.IndexWorker]),
        # Cache workers
        worker(TdBg.Cache.ConceptLoader, []),
        worker(TdBg.Cache.DomainLoader, [TdBg.Cache.DomainLoader]),
        # Metrics worker
        %{
          id: TdBg.CustomSupervisor,
          start:
            {TdBg.CustomSupervisor, :start_link,
             [%{children: [metrics_worker], strategy: :one_for_one}]},
          type: :supervisor
        }
      ] ++ startup_tasks(env)

    PrometheusExporter.setup()
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

  defp startup_tasks(:test), do: []

  defp startup_tasks(_env) do
    # Task to reindex on startup if necessary
    [{TdBg.Search.Reindex, []}]
  end
end
