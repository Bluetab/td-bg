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

  @impl TdCache.EventStream.Consumer
  def consume(events) do
    GenServer.cast(__MODULE__, {:consume, events})
  end

  ## GenServer Callbacks

  @impl GenServer
  def init(_init_arg) do
    name = String.replace_prefix("#{__MODULE__}", "Elixir.", "")
    Logger.info("Running #{name}")

    state = %{env: Application.get_env(:td_bg, :env)}

    unless state.env == :test do
      Process.send_after(self(), :migrate, 0)
    end

    {:ok, state}
  end

  @impl GenServer
  def handle_info(:migrate, state) do
    Indexer.migrate()
    {:noreply, state}
  end

  @impl GenServer
  def handle_call({:reindex, ids}, _from, state) do
    reply = do_reindex(ids)
    {:reply, reply, state}
  end

  @impl GenServer
  def handle_cast({:reindex, :all}, %{env: env} = state) do
    unless env == :test do
      do_reindex(:all)
    end

    {:noreply, state}
  end

  @impl GenServer
  def handle_cast({:consume, events}, state) do
    case Enum.any?(events, &reindex_event?/1) do
      true -> do_reindex(:all)
      _ -> :ok
    end

    {:noreply, state}
  end

  ## Private functions

  defp do_reindex([]), do: :ok

  defp do_reindex(:all) do
    Logger.info("Reindexing all concepts")

    Timer.time(
      fn -> Indexer.reindex(:all) end,
      fn ms, _ -> Logger.info("Reindexed all concepts in #{ms}ms") end
    )
  end

  defp do_reindex(ids) when is_list(ids) do
    count = Enum.count(ids)

    Timer.time(
      fn -> Indexer.reindex(ids) end,
      fn ms, _ -> Logger.info("Reindexed #{count} concepts in #{ms}ms") end
    )
  end

  defp reindex_event?(%{event: "template_updated", scope: "bg"}), do: true

  defp reindex_event?(_), do: false
end
