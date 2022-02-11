defmodule TdBg.Cache.DomainLoader do
  @moduledoc """
  GenServer to load taxonomy hierarchy into Redis
  """

  use GenServer

  alias TdBg.Taxonomies
  alias TdCache.TaxonomyCache

  require Logger

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def refresh(domain_id, opts \\ []) do
    GenServer.call(__MODULE__, {:refresh, domain_id, opts})
  end

  def refresh_deleted do
    GenServer.cast(__MODULE__, :refresh_deleted)
  end

  def delete(domain_id) do
    GenServer.call(__MODULE__, {:delete, domain_id})
  end

  @impl true
  def init(state) do
    {:ok, state}
  end

  @impl true
  def handle_call({:refresh, :all, opts}, _from, state) do
    load_domains(opts)
    {:reply, :ok, state}
  end

  @impl true
  def handle_call({:refresh, domain_id, opts}, _from, state) do
    load_domain(domain_id, opts)
    {:reply, :ok, state}
  end

  @impl true
  def handle_call({:delete, domain_id}, _from, state) do
    TaxonomyCache.delete_domain(domain_id)
    load_domains(force: true, publish: false)
    {:reply, :ok, state}
  end

  @impl true
  def handle_cast(:refresh_deleted, state) do
    remove_deleted_domains()
    {:noreply, state}
  end

  defp load_domain(domain_id, opts) do
    domain = Taxonomies.get_domain!(domain_id)

    [domain]
    |> load_domain_data(opts)
  end

  defp load_domains(opts) do
    Taxonomies.list_domains()
    |> load_domain_data(opts)
  end

  defp remove_deleted_domains do
    {results, errors} =
      %{}
      |> Taxonomies.list_domains(deleted: true)
      |> Enum.map(&TaxonomyCache.delete_domain(&1.id))
      |> Enum.split_with(fn {:ok, _} -> true end)

    if length(errors) > 0 do
      Logger.warn("Cache deletion failed with #{length(errors)} errors")
    else
      remove_count =
        Enum.reduce(results, 0, fn
          {:ok, [_, _, _, _, _, n]}, acc when is_integer(n) -> acc + n
          _, acc -> acc
        end)

      if remove_count > 0 do
        Logger.info("Removed #{remove_count} deleted domains")
        load_domains(force: true, publish: false)
      end
    end
  end

  def load_domain_data(domains, opts) do
    results =
      domains
      |> Enum.map(&Map.take(&1, [:id, :parent_id, :name, :external_id, :updated_at]))
      |> Enum.map(&TaxonomyCache.put_domain(&1, opts))
      |> Enum.map(fn {res, _} -> res end)

    if Enum.any?(results, &(&1 != :ok)) do
      Logger.warn("Cache loading failed")
    else
      Logger.info("Cached #{length(results)} domains")
    end
  end
end
