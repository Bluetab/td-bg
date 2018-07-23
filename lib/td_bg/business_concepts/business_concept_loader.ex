defmodule TdBg.BusinessConceptLoader do
  @moduledoc """
  GenServer to load business concepts into Redis
  """

  use GenServer

  alias TdBg.BusinessConcepts
  alias TdPerms.BusinessConceptCache

  require Logger

  @cache_busines_concepts_on_startup Application.get_env(:td_bg, :cache_busines_concepts_on_startup)

  def start_link(name \\ nil) do
    GenServer.start_link(__MODULE__, nil, [name: name])
  end

  def refresh(business_concept_id) do
    GenServer.call(TdBg.BusinessConceptLoader, {:refresh, business_concept_id})
  end

  def delete(business_concept_id) do
    GenServer.call(TdBg.BusinessConceptLoader, {:delete, business_concept_id})
  end

  @impl true
  def init(state) do
    if @cache_busines_concepts_on_startup, do: schedule_work(:load_bc_cache, 0)
    {:ok, state}
  end

  @impl true
  def handle_call({:refresh, business_concept_id}, _from, state) do
    load_business_concept(business_concept_id)
    {:reply, :ok, state}
  end

  @impl true
  def handle_call({:delete, business_concept_id}, _from, state) do
    BusinessConceptCache.delete_business_concept(business_concept_id)
    {:reply, :ok, state}
  end

  @impl true
  def handle_info(:load_bc_cache, state) do
    load_all_business_concepts()

    {:noreply, state}
  end

  defp schedule_work(action, seconds) do
    Process.send_after(self(), action, seconds)
  end

  defp load_business_concept(business_concept_id) do
    business_concept = business_concept_id
      |> BusinessConcepts.get_current_version_by_business_concept_id!()
      |> load_bc_version_data()
    [business_concept]
    |> load_business_concept_data()
  end

  defp load_all_business_concepts do
    BusinessConcepts.list_current_business_concept_versions()
    |> Enum.map(&(load_bc_version_data/1))
    |> load_business_concept_data()
  end

  defp load_bc_version_data(business_concept_version) do
    %{id: business_concept_version.business_concept_id, domain_id: business_concept_version.business_concept.domain_id,
      name: business_concept_version.name}
  end

  def load_business_concept_data(business_concepts) do
    results = business_concepts
    |> Enum.map(&(Map.take(&1, [:id, :domain_id, :name])))
    |> Enum.map(&(BusinessConceptCache.put_business_concept(&1)))
    |> Enum.map(fn {res, _} -> res end)

    if Enum.any?(results, &(&1 != :ok)) do
      Logger.warn("Cache loading of business concepts failed")
    else
      Logger.info("Cached #{length(results)} business concepts")
    end
  end

end
