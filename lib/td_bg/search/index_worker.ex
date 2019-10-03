defmodule TdBg.Search.IndexWorker do
  @moduledoc """
  GenServer to reindex business concepts
  """

  @behaviour TdCache.EventStream.Consumer

  use GenServer

  alias TdBg.Search.Indexer

  require Logger

  ## Client API

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def ping(timeout \\ 5000) do
    GenServer.call(__MODULE__, :ping, timeout)
  end

  def reindex(:all) do
    GenServer.cast(__MODULE__, {:reindex, :all})
  end

  def reindex(ids) when is_list(ids) do
    GenServer.call(__MODULE__, {:reindex, ids}, 30_000)
  end

  def reindex(id) do
    reindex([id])
  end

  ## EventStream.Consumer Callbacks

  @impl true
  def consume(events) do
    GenServer.cast(__MODULE__, {:consume, events})
  end

  ## GenServer Callbacks

  @impl true
  def init(state) do
    name = String.replace_prefix("#{__MODULE__}", "Elixir.", "")
    Logger.info("Running #{name}")

    unless Application.get_env(:td_bg, :env) == :test do
      Process.send_after(self(), :migrate, 0)
    end

    {:ok, state}
  end

  @impl GenServer
  def handle_info(:migrate, state) do
    Indexer.migrate()
    {:noreply, state}
  end

  @impl true
  def handle_call(:ping, _from, state) do
    {:reply, :pong, state}
  end

  @impl true
  def handle_call({:reindex, ids}, _from, state) do
    reply = do_reindex(ids)
    {:reply, reply, state}
  end

  @impl true
  def handle_cast({:reindex, :all}, state) do
    do_reindex(:all)

    {:noreply, state}
  end

  @impl true
  def handle_cast({:consume, events}, state) do
    case Enum.any?(events, &reindex_event?/1) do
      true -> do_reindex(:all)
      _ -> :ok
    end

    {:noreply, state}
  end

  defp do_reindex(ids) do
    Timer.time(
      fn -> Indexer.reindex(ids) end,
      fn millis, _ -> Logger.info("Business concepts indexed in #{millis}ms") end
    )
  end

  defp reindex_event?(%{event: "add_template", scope: "bg"}), do: true

  defp reindex_event?(_), do: false
end
