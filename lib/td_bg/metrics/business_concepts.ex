defmodule TdBg.Metrics.BusinessConcepts do
  @moduledoc """
  Business Glossary Metrics GenServer.
  """

  use GenServer

  alias TdBg.Metrics.Completeness
  alias TdBg.Metrics.Count
  alias TdBg.Metrics.Instrumenter
  alias TdBg.Search

  require Logger

  @metrics_publication_frequency Application.get_env(:td_bg, :metrics_publication_frequency)

  ## Client API

  def start_link(opts \\ %{}) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def count do
    GenServer.call(__MODULE__, :count)
  end

  def completeness do
    GenServer.call(__MODULE__, :completeness)
  end

  ## GenServer Callbacks

  @impl true
  def init(state) do
    if Application.get_env(:td_bg, :env) == :prod do
      schedule_work()
    end

    {:ok, state}
  end

  @impl true
  def handle_info(:work, state) do
    Instrumenter.setup()

    concepts = search_all_concepts()

    Timer.time(
      fn -> Count.transform(concepts) end,
      &Logger.info("Calculated #{Enum.count(&2)} concept count metrics in #{&1}ms")
    )
    |> Enum.each(&Instrumenter.set_count/1)

    Timer.time(
      fn -> Completeness.transform(concepts) end,
      &Logger.info("Calculated #{Enum.count(&2)} completeness metrics in #{&1}ms")
    )
    |> Enum.each(&Instrumenter.set_completeness/1)

    # Reschedule once more
    schedule_work()
    {:noreply, state}
  end

  @impl true
  def handle_call(:count, _from, state) do
    reply =
      search_all_concepts()
      |> Count.transform()

    {:reply, reply, state}
  end

  @impl true
  def handle_call(:completenes, _from, state) do
    reply =
      search_all_concepts()
      |> Completeness.transform()

    {:reply, reply, state}
  end

  ## Private Functions

  defp search_all_concepts do
    Timer.time(
      fn ->
        Search.search(%{
          query: %{bool: %{must: %{match_all: %{}}}},
          size: 10_000
        })
      end,
      fn ms, _ -> Logger.info("Search all concepts completed in #{ms}ms") end
    )
  end

  defp schedule_work do
    Process.send_after(self(), :work, @metrics_publication_frequency)
  end
end
