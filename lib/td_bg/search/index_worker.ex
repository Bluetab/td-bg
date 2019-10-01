defmodule TdBg.Search.IndexWorker do
  @moduledoc """
  GenServer to reindex business concepts
  """

  use GenServer

  alias TdBg.Search.Indexer

  require Logger

  def start_link(name \\ nil) do
    GenServer.start_link(__MODULE__, nil, name: name)
  end

  def ping do
    GenServer.call(__MODULE__, :ping)
  end

  def reindex(:all) do
    GenServer.cast(__MODULE__, {:reindex, :all})
  end

  def reindex(ids) when is_list(ids) do
    GenServer.call(__MODULE__, {:reindex, ids})
  end

  def reindex(id) do
    reindex([id])
  end

  @impl true
  def init(state) do
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
    Logger.info("Reindexing all business concepts")
    start_time = DateTime.utc_now()
    Indexer.reindex(:business_concept)
    millis = DateTime.utc_now() |> DateTime.diff(start_time, :millisecond)
    Logger.info("Business concepts indexed in #{millis}ms")

    {:noreply, state}
  end
end
