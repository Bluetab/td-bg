defmodule TdBg.Cache.ConceptLoader do
  @moduledoc """
  Loads business concept data into cache.
  """

  @behaviour TdCache.EventStream.Consumer

  use GenServer

  alias TdBg.BusinessConcepts
  alias TdBg.BusinessConcepts.BusinessConcept
  alias TdBg.BusinessConcepts.BusinessConceptVersion
  alias TdBg.I18nContents.I18nContents
  alias TdBg.Search.Indexer
  alias TdCache.ConceptCache
  alias TdCache.Redix

  require Logger

  @seconds_in_day 60 * 60 * 24
  @concept_props [:id, :domain_id, :type, :confidential]
  @version_props [:name, :status, :version]

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
      Process.send_after(self(), :put_ids, 200)
    end

    name = String.replace_prefix("#{__MODULE__}", "Elixir.", "")
    Logger.info("Running #{name}")
    {:ok, state}
  end

  @impl GenServer
  def handle_info(:refresh_all, state) do
    # Full refresh on startup, only if last full refresh was more than one day ago
    if acquire_lock?("TdBg.Cache.ConceptLoader:TD-3063", @seconds_in_day) ||
         acquire_lock?("TdBg.Cache.ConceptLoader:TD-6197") ||
         acquire_lock?("TdBg.Cache.ConceptLoader:TD-6735") ||
         acquire_lock?("TdBg.Cache.ConceptLoader:TD-6469") ||
         acquire_lock?("TdBg.Cache.ConceptLoader:TD-6901") do
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
    Indexer.reindex(ids)
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

    unless ids == [] do
      Indexer.reindex(ids)
    end

    ids
  end

  defp reindex_all(events) do
    ids =
      events
      |> Enum.filter(&(&1.event == "add_rule"))
      |> Enum.flat_map(&read_concept_ids/1)

    unless ids == [] do
      Indexer.reindex(:all)
    end

    ids
  end

  ## Private functions

  defp read_concept_ids(%{event: "add_link", source: source, target: target}) do
    [source, target]
    |> Enum.filter(&String.starts_with?(&1, "business_concept:"))
    |> Enum.flat_map(&do_read_concept_ids/1)
  end

  defp read_concept_ids(%{event: "add_rule", concept: concept}) do
    do_read_concept_ids(concept)
  end

  defp read_concept_ids(%{event: "remove_rule", concept: concept}) do
    do_read_concept_ids(concept)
  end

  defp read_concept_ids(%{event: "add_comment"}) do
    []
  end

  # unsupported events...
  defp read_concept_ids(_), do: []

  defp do_read_concept_ids(value) do
    case read_concept_id(value) do
      {:ok, id} ->
        [id]

      _ ->
        Logger.warning("Invalid format #{value}")
        []
    end
  end

  defp read_concept_id(value) do
    case Regex.run(~r/^business_concept:(\d+)$/, value, capture: :all_but_first) do
      [id] ->
        {:ok, String.to_integer(id)}

      _ ->
        {:error, :invalid_format}
    end
  end

  defp cache_concepts(business_concept_ids) do
    business_concept_ids
    |> get_published_or_current_versions()
    |> Enum.map(&to_cache_entry(&1))
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
    |> Enum.find(&published_or_current?/1)
  end

  defp published_or_current?(%BusinessConceptVersion{status: "published"}), do: true
  defp published_or_current?(%BusinessConceptVersion{current: true}), do: true
  defp published_or_current?(_), do: false

  defp get_business_concept_i18n(%BusinessConceptVersion{id: id}) do
    id
    |> I18nContents.get_all_i18n_content_by_bcv_id()
    |> Enum.filter(&get_content/1)
    |> Enum.group_by(& &1.lang, &Map.take(&1, [:name, :content]))
    |> Enum.map(fn {lang, [i18n]} -> {lang, i18n} end)
    |> Map.new()
  end

  defp to_cache_entry(%BusinessConceptVersion{business_concept: c} = bcv) do
    bcv
    |> version_props()
    |> Map.merge(concept_props(c))
    |> Map.put(:content, get_content(bcv))
    |> Map.put(:i18n, get_business_concept_i18n(bcv))
  end

  defp get_content(%{} = bcv) do
    bcv
    |> Map.get(:content, %{})
    |> Enum.filter(&valid_value?/1)
    |> Map.new()
  end

  defp valid_value?({_key, %{"value" => value}}) when is_binary(value) do
    valid?(value)
  end

  defp valid_value?({_key, %{"value" => %{"document" => document}}}) do
    has_text?(document)
  end

  defp valid_value?({_key, %{"value" => [_ | _] = values}}) do
    Enum.all?(values, &valid?(&1))
  end

  defp valid_value?({_key, [_ | _] = values}) do
    Enum.all?(values, &valid?(&1))
  end

  defp valid_value?(_), do: false

  defp valid?(value) when is_binary(value) do
    String.trim(value) != ""
  end

  defp valid?(_), do: false

  def has_text?(%{"nodes" => nodes}) do
    Enum.any?(nodes, &has_text?/1)
  end

  def has_text?(%{"object" => "text", "text" => text}) do
    String.trim(text) != ""
  end

  def has_text?(_), do: false

  defp concept_props(%BusinessConcept{} = business_concept) do
    shared_to_ids =
      business_concept
      |> Map.get(:shared_to, [])
      |> Enum.map(& &1.id)

    business_concept
    |> Map.take(@concept_props)
    |> Map.put(:shared_to_ids, shared_to_ids)
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

  defp acquire_lock?(key) do
    Redix.command!(["SET", key, node(), "NX"])
  end
end
