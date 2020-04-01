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
  alias TdCache.Redix
  alias TdCache.TemplateCache

  require Logger

  @seconds_in_day 60 * 60 * 24
  @concept_props [:id, :domain_id, :type]
  @version_props [:id, :name, :status, :version]

  ## Client API

  def start_link(config \\ []) do
    GenServer.start_link(__MODULE__, config, name: __MODULE__)
  end

  def refresh(business_concept_ids) when is_list(business_concept_ids) do
    GenServer.call(__MODULE__, {:refresh, business_concept_ids})
  end

  def refresh(business_concept_id) do
    refresh([business_concept_id])
  end

  ## EventStream.Consumer Callbacks

  @impl TdCache.EventStream.Consumer
  def consume(events) do
    GenServer.call(__MODULE__, {:consume, events})
  end

  ## GenServer Callbacks

  @impl GenServer
  def init(state) do
    unless Application.get_env(:td_bg, :env) == :test do
      Process.send_after(self(), :refresh_all, 200)
    end

    unless Application.get_env(:td_bg, :env) == :test do
      Process.send_after(self(), :put_ids, 200)
    end

    name = String.replace_prefix("#{__MODULE__}", "Elixir.", "")
    Logger.info("Running #{name}")
    {:ok, state}
  end

  @impl GenServer
  def handle_info(:refresh_all, state) do
    # Full refresh on startup, only if last full refresh was more than one day ago
    if acquire_lock?("TdBg.Cache.ConceptLoader:REFRESH", @seconds_in_day) do
      Timer.time(
        fn ->
          BusinessConcepts.get_active_ids()
          |> cache_concepts()
        end,
        fn ms, _ ->
          Logger.info("Full refresh completed in #{ms}ms")
        end
      )
    end

    {:noreply, state}
  end

  @impl GenServer
  def handle_info(:put_ids, state) do
    put_active_ids()
    put_confidential_ids()
    {:noreply, state}
  end

  @impl GenServer
  def handle_call({:refresh, ids}, _from, state) do
    reply = cache_concepts(ids)
    IndexWorker.reindex(ids)
    {:reply, reply, state}
  end

  @impl GenServer
  def handle_call({:consume, events}, _from, state) do
    concept_ids = reindex(events) ++ reindex_all(events)
    reply = cache_concepts(concept_ids)
    {:reply, reply, state}
  end

  defp reindex(events) do
    ids =
      events
      |> Enum.filter(&(&1.event != "add_rule"))
      |> Enum.flat_map(&read_concept_ids/1)

    IndexWorker.reindex(ids)

    ids
  end

  defp reindex_all(events) do
    ids =
      events
      |> Enum.filter(&(&1.event == "add_rule"))
      |> Enum.flat_map(&read_concept_ids/1)

    IndexWorker.reindex(:all)

    ids
  end

  ## Private functions

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
    content_fields = TemplateCache.fields_by_type!("bg", "user")

    business_concept_ids
    |> get_published_or_current_versions()
    |> Enum.group_by(& &1.business_concept.type)
    |> Enum.map(fn {type, concepts} -> {Map.get(content_fields, type, []), concepts} end)
    |> Enum.flat_map(fn {fields, concepts} -> Enum.map(concepts, &to_cache_entry(&1, fields)) end)
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

  defp to_cache_entry(%BusinessConceptVersion{business_concept: c} = bcv, content_fields) do
    bcv
    |> version_props()
    |> Map.merge(concept_props(c))
    |> Map.put(:content, get_content(bcv, content_fields))
  end

  defp get_content(%BusinessConceptVersion{} = bcv, fields) do
    bcv
    |> Map.get(:content, %{})
    |> Map.take(fields)
    |> Enum.filter(&valid_value?/1)
    |> Map.new()
  end

  defp valid_value?({_key, value}) when is_binary(value) do
    String.trim(value) != ""
  end

  defp valid_value?(_), do: false

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

  defp acquire_lock?(key, expiry_seconds) do
    Redix.command!(["SET", key, node(), "NX", "EX", expiry_seconds])
  end
end
