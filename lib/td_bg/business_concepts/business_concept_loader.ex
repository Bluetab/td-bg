defmodule TdBg.BusinessConceptLoader do
  @moduledoc """
  GenServer to load business concepts into Redis
  """

  use GenServer

  alias TdBg.BusinessConcepts
  alias TdPerms.BusinessConceptCache

  require Logger

  @cache_busines_concepts_on_startup Application.get_env(
                                       :td_bg,
                                       :cache_busines_concepts_on_startup
                                     )

  def start_link(name \\ nil) do
    GenServer.start_link(__MODULE__, nil, name: name)
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

  defp load_all_business_concepts do
    BusinessConcepts.list_all_business_concepts()
    |> Enum.map(&load_business_concept(&1.id))
  end

  defp load_business_concept(business_concept_id) do
    business_concept =
      business_concept_id
      |> BusinessConcepts.get_currently_published_version!()
      |> load_bc_version_data()

    load_business_concept_data(business_concept)
  end

  defp load_bc_version_data(business_concept_version) do
    %{
      id: business_concept_version.business_concept_id,
      domain_id: business_concept_version.business_concept.domain_id,
      name: business_concept_version.name,
      current_version: business_concept_version.version,
      business_concept_version_id: business_concept_version.id,
      status: business_concept_version.status,
      parent_id: business_concept_version.business_concept.parent_id
    }
  end

  def load_business_concept_data(business_concept) do
    put_business_concepts_in_cache(business_concept)
    put_business_concepts_in_deprecated_set(business_concept)
    put_bc_parents_in_cache(business_concept)
  end

  defp put_business_concepts_in_cache(business_concept) do
    result =
      business_concept
      |> Map.take([:id, :domain_id, :name, :current_version, :business_concept_version_id])
      |> BusinessConceptCache.put_business_concept

    case result do
      {:ok, _} -> Logger.info("Cached business concepts")
      _ -> Logger.warn("Cache loading of business concept failed")
    end
  end

  defp put_business_concepts_in_deprecated_set(%{status: "deprecated"} = business_concept) do
    result =
      business_concept
      |> Map.get(:id)
      |> BusinessConceptCache.add_business_concept_to_deprecated_set

    case result do
      {:ok, _} -> Logger.info("Added business concept to deprecated terms set")
      _ -> Logger.warn("Cache loading of deprecated business concept failed")
    end
  end
  defp put_business_concepts_in_deprecated_set(_), do: nil

  defp put_bc_parents_in_cache(%{parent_id: nil}), do: nil
  defp put_bc_parents_in_cache(business_concept) do
    result = BusinessConceptCache.put_bc_parent(business_concept)

    case result do
      {:ok, _} -> Logger.info("Added business concept parent")
      _ -> Logger.warn("Cache loading of business concept parent failed")
    end
  end
end
