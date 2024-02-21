defmodule TdBg.Application do
  @moduledoc false

  use Application

  alias TdBgWeb.Endpoint

  @impl true
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

  @impl true
  def config_change(changed, _new, removed) do
    Endpoint.config_change(changed, removed)
    :ok
  end

  defp workers(:test), do: []

  defp workers(_env) do
    [
      # Task supervisor
      {Task.Supervisor, name: TdBg.TaskSupervisor},
      # Cache workers
      TdBg.Cache.ConceptLoader,
      TdBg.Cache.DomainLoader,
      TdBg.Scheduler,
      # Bulk Uploader worker
      TdBg.BusinessConcepts.BulkUploader
    ]
  end
end
