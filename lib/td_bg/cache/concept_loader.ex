defmodule TdBg.Cache.ConceptLoader do
  @moduledoc """
  Loads business concept data into cache.
  """

  @behaviour TdCache.EventStream.Consumer

  use GenServer

  alias TdBg.BusinessConcepts
  alias TdBg.BusinessConcepts.BusinessConcept
  alias TdBg.BusinessConcepts.BusinessConceptVersion
  alias TdBg.Search.IndexWorker
  alias TdCache.ConceptCache

  require Logger

  ## Client API

  def start_link(config \\ []) do
    GenServer.start_link(__MODULE__, config, name: __MODULE__)
  end

  def ping(timeout \\ 5000) do
    GenServer.call(__MODULE__, :ping, timeout)
  end

  def refresh(business_concept_ids) when is_list(business_concept_ids) do
    GenServer.call(__MODULE__, {:refresh, business_concept_ids})
  end

  def refresh(business_concept_id) do
    refresh([business_concept_id])
  end

  ## EventStream.Consumer Callbacks

  @impl true
  def consume(events) do
    GenServer.call(__MODULE__, {:consume, events}, 20_000)
  end

  ## GenServer Callbacks

  @impl true
  def init(state) do
    unless Application.get_env(:td_bg, :env) == :test do
      Process.send_after(self(), :put_ids, 200)
    end

    name = String.replace_prefix("#{__MODULE__}", "Elixir.", "")
    Logger.info("Running #{name}")
    {:ok, state}
  end

  @impl true
  def handle_info(:put_ids, state) do
    put_active_ids()
    put_confidential_ids()
    {:noreply, state}
  end

  @impl true
  def handle_call(:ping, _from, state) do
    {:reply, :pong, state}
  end

  @impl true
  def handle_call({:refresh, ids}, _from, state) do
    reply = cache_concepts(ids)
    IndexWorker.reindex(ids)
    {:reply, reply, state}
  end

  @impl true
  def handle_call({:consume, events}, _from, state) do
    concept_ids =
      events
      |> Enum.flat_map(&read_concept_ids/1)

    reply = cache_concepts(concept_ids)
    IndexWorker.reindex(concept_ids)
    {:reply, reply, state}
  end

  ## Private functions

  @concept_props [:id, :domain_id, :type]
  @version_props [:id, :content, :name, :status, :version]

  defp read_concept_ids(%{event: "add_link", source: source, target: target}) do
    [source, target]
    |> Enum.filter(&String.starts_with?(&1, "business_concept:"))
    |> Enum.map(&read_concept_id/1)
  end

  defp read_concept_ids(%{event: "add_rule", concept: concept}) do
    do_read_concept_ids(concept)
  end

  defp read_concept_ids(%{event: "remove_rule", concept: concept}) do
    do_read_concept_ids(concept)
  end

  defp read_concept_ids(%{event: "add_comment"}) do
    # TODO: Do we need to do anything with this event?
    []
  end

  # unsupported events...
  defp read_concept_ids(_), do: []

  defp do_read_concept_ids(value) do
    case read_concept_id(value) do
      {:ok, id} ->
        [id]

      _ ->
        Logger.warn("Invalid format #{value}")
        []
    end
  end

  defp read_concept_id(value) do
    case Regex.run(~r/^business_concept:(\d+)$/, value, capture: :all_but_first) do
      [id] -> {:ok, String.to_integer(id)}
      _ -> {:error, :invalid_format}
    end
  end

  defp cache_concepts(business_concept_ids) do
    business_concept_ids
    |> get_published_or_current_versions
    |> Enum.map(&to_cache_entry/1)
    |> Enum.map(&put_cache/1)
  end

  defp get_published_or_current_versions(business_concept_ids) do
    business_concept_ids
    |> BusinessConcepts.get_all_versions_by_business_concept_ids()
    |> Enum.group_by(& &1.business_concept_id)
    |> Enum.map(&published_or_current_version/1)
    |> Enum.filter(& &1)
  end

  defp published_or_current_version({_id, versions}) do
    versions
    |> Enum.sort(&(&1.version > &2.version))
    |> Enum.find(&is_published_or_current?/1)
  end

  defp is_published_or_current?(%BusinessConceptVersion{status: "published"}), do: true
  defp is_published_or_current?(%BusinessConceptVersion{current: true}), do: true
  defp is_published_or_current?(_), do: false

  defp to_cache_entry(
         %BusinessConceptVersion{business_concept: business_concept} = business_concept_version
       ) do
    business_concept_version
    |> version_props
    |> Map.merge(concept_props(business_concept))
  end

  defp concept_props(%BusinessConcept{} = business_concept) do
    Map.take(business_concept, @concept_props)
  end

  defp version_props(%BusinessConceptVersion{id: id} = business_concept_version) do
    business_concept_version
    |> Map.take(@version_props)
    |> Map.put(:business_concept_version_id, id)
  end

  defp put_cache(entry) do
    ConceptCache.put(entry)
  end

  defp put_active_ids do
    case BusinessConcepts.get_active_ids() do
      [] -> {:ok, []}
      ids -> ConceptCache.put_active_ids(ids)
    end
  end

  defp put_confidential_ids do
    case BusinessConcepts.get_confidential_ids() do
      [] -> {:ok, []}
      ids -> ConceptCache.put_confidential_ids(ids)
    end
  end
end
