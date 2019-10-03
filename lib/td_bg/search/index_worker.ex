defmodule TdBg.Search.IndexWorker do
  @moduledoc """
  GenServer to reindex business concepts
  """

  @behaviour TdCache.EventStream.Consumer

  use GenServer

  alias TdBg.Search.Indexer

  require Logger

  ## Client API

  def start_link(name \\ nil) do
    GenServer.start_link(__MODULE__, nil, name: name)
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
    {:ok, state}
  end

  @impl true
  def handle_call(:ping, _from, state) do
    {:reply, :pong, state}
  end

  @impl true
  def handle_call({:reindex, ids}, _from, state) do
    Logger.info("Reindexing #{Enum.count(ids)} business concepts")
    start_time = DateTime.utc_now()
    reply = Indexer.reindex(ids, :business_concept)
    millis = DateTime.utc_now() |> DateTime.diff(start_time, :millisecond)
    Logger.info("Business concepts indexed in #{millis}ms")

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

  defp do_reindex(:all) do
    Logger.info("Reindexing all business concepts")
    start_time = DateTime.utc_now()
    Indexer.reindex(:business_concept)
    millis = DateTime.utc_now() |> DateTime.diff(start_time, :millisecond)
    Logger.info("Business concepts indexed in #{millis}ms")
  end

  defp reindex_event?(%{event: "add_template", scope: "bg"}), do: true

  defp reindex_event?(_), do: false
end
