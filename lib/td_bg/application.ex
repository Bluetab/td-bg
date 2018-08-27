defmodule TdBg.Application do
  @moduledoc false
  use Application
  alias TdBg.Metrics.PrometheusExporter
  alias TdBgWeb.Endpoint

  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec

    # Define workers and child supervisors to be supervised
    children = [
      # Start the Ecto repository
      supervisor(TdBg.Repo, []),
      # Start the endpoint when the application starts
      supervisor(TdBgWeb.Endpoint, []),
      # Start your own worker by calling:
      # TdBg.Worker.start_link(arg1, arg2, arg3)
      # worker(TdBg.Worker, [arg1, arg2, arg3]),
      worker(TdBg.DomainLoader, [TdBg.DomainLoader]),
      worker(TdBg.BusinessConceptLoader, [TdBg.BusinessConceptLoader]),
      #worker(TdBg.Metrics.BusinessConcepts, [])
    ]

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
end
