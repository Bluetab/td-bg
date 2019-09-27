defmodule TdBg.Cache.TemplateLoader do
  @moduledoc """
  Loads template to consume df events 
  """

  @behaviour TdCache.EventStream.Consumer

  use GenServer

  alias TdBg.Search.IndexWorker

  require Logger

  ## Client API
  def start_link(config \\ []) do
    GenServer.start_link(__MODULE__, config, name: __MODULE__)
  end

  ## EventStream.Consumer Callbacks

  @impl true
  def consume(events) do
    GenServer.call(__MODULE__, {:consume, events})
  end

  @impl true
  def init(state) do
    name = String.replace_prefix("#{__MODULE__}", "Elixir.", "")
    Logger.info("Running #{name}")
    {:ok, state}
  end

  @impl true
  def handle_call({:consume, events}, _from, state) do
    reply =
      events
      |> Enum.filter(&reindex_event?/1)
      |> Enum.count()
      |> case do
        0 -> :ok
        _ -> 
            IndexWorker.reindex(:all)
            :ok
      end

    {:reply, reply, state}
  end

  defp reindex_event?(%{event: "add_template", scope: "bg"}), do: true

  defp reindex_event?(_), do: false
end
