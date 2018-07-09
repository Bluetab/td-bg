defmodule TdBg.DomainLoader do
  @moduledoc """
  GenServer to load taxonomy hierarchy into Redis
  """

  use GenServer

  alias TdBg.Taxonomies
  alias TdPerms.TaxonomyCache

  require Logger

  @cache_domains_on_startup Application.get_env(:td_bg, :cache_domains_on_startup)

  def start_link(name \\ nil) do
    GenServer.start_link(__MODULE__, nil, [name: name])
  end

  def refresh(domain_id) do
    GenServer.call(TdBg.DomainLoader, {:refresh, domain_id})
  end

  def delete(domain_id) do
    GenServer.call(TdBg.DomainLoader, {:delete, domain_id})
  end

  @impl true
  def init(state) do
    if @cache_domains_on_startup, do: schedule_work(:load_cache, 0)
    {:ok, state}
  end

  @impl true
  def handle_call({:refresh, domain_id}, _from, state) do
    load_domain(domain_id)
    {:reply, :ok, state}
  end

  @impl true
  def handle_call({:delete, domain_id}, _from, state) do
    TaxonomyCache.delete_domain(domain_id)
    {:reply, :ok, state}
  end

  @impl true
  def handle_info(:load_cache, state) do
    load_all_domains()

    {:noreply, state}
  end

  defp schedule_work(action, seconds) do
    Process.send_after(self(), action, seconds)
  end

  defp load_domain(domain_id) do
    domain = Taxonomies.get_domain!(domain_id)
    [domain]
    |> load_domain_data()
  end

  defp load_all_domains do
    Taxonomies.list_domains()
    |> load_domain_data()
  end

  def load_domain_data(domains) do
    results = domains
    |> Enum.map(&(Map.take(&1, [:id, :name])))
    |> Enum.map(&(Map.put(&1, :parent_ids, load_parent_ids(&1.id))))
    |> Enum.map(&(TaxonomyCache.put_domain(&1)))
    |> Enum.map(fn {res, _} -> res end)

    if Enum.any?(results, &(&1 != :ok)) do
      Logger.warn("Cache loading failed")
    else
      Logger.info("Cached #{length(results)} domains")
    end
  end

  defp load_parent_ids(domain_id) do
    domain_id
    |> Taxonomies.get_ancestors_for_domain_id(false)
    |> Enum.map(&(&1.id))
  end

end
