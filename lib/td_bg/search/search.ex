defmodule TdBg.Search do
  @moduledoc """
  Search Engine calls
  """

  alias TdBg.Search.Cluster
  alias TdCache.HierarchyCache
  alias TdCache.TaxonomyCache

  require Logger

  @index "concepts"

  def search(query) do
    response =
      Elasticsearch.post(Cluster, "/#{@index}/_search", query,
        params: %{"track_total_hits" => "true"}
      )

    case response do
      {:ok, %{"aggregations" => aggregations, "hits" => %{"hits" => results, "total" => total}}} ->
        %{results: results, total: get_total(total), aggregations: aggregations}

      {:ok, %{"hits" => %{"hits" => results, "total" => total}}} ->
        %{results: results, total: get_total(total), aggregations: %{}}

      {:error, %Elasticsearch.Exception{message: message} = error} ->
        Logger.warn("Error response from Elasticsearch: #{message}")
        error
    end
  end

  def get_filters(query) do
    response = Elasticsearch.post(Cluster, "/#{@index}/_search", query)

    case response do
      {:ok, %{"aggregations" => aggregations}} ->
        aggregations
        |> Map.to_list()
        |> Enum.into(%{}, &filter_values/1)

      {:error, %Elasticsearch.Exception{message: message} = error} ->
        Logger.warn("Error response from Elasticsearch: #{message}")
        error
    end
  end

  defp filter_values({"taxonomy", %{"buckets" => buckets}}) do
    domains =
      buckets
      |> Enum.flat_map(fn %{"key" => domain_id} ->
        TaxonomyCache.reaching_domain_ids(domain_id)
      end)
      |> Enum.uniq()
      |> Enum.map(&get_domain/1)
      |> Enum.reject(&is_nil/1)

    {"taxonomy",
     %{
       type: :domain,
       values: domains
     }}
  end

  defp filter_values({name, %{"meta" => %{"type" => "domain"}, "buckets" => buckets}}) do
    domains =
      buckets
      |> Enum.map(fn %{"key" => domain_id} -> get_domain(domain_id) end)
      |> Enum.reject(&is_nil/1)

    {name,
     %{
       type: :domain,
       values: domains
     }}
  end

  defp filter_values({name, %{"meta" => %{"type" => "hierarchy"}, "buckets" => buckets}}) do
    node_names =
      buckets
      |> Enum.map(fn %{"key" => key} -> get_hierarchy_node(key) end)
      |> Enum.reject(&is_nil/1)

    {name,
     %{
       type: :hierarchy,
       values: node_names
     }}
  end

  defp filter_values({name, %{"buckets" => buckets}}) do
    {name, %{values: Enum.map(buckets, &bucket_key/1)}}
  end

  defp filter_values({name, %{"distinct_search" => distinct_search}}) do
    filter_values({name, distinct_search})
  end

  defp filter_values({name, %{"doc_count" => 0}}), do: {name, %{values: []}}

  defp bucket_key(%{"key_as_string" => key}) when key in ["true", "false"], do: key
  defp bucket_key(%{"key" => key}), do: key

  defp get_domain(""), do: nil
  defp get_domain(id) when is_integer(id) or is_binary(id), do: TaxonomyCache.get_domain(id)
  defp get_domain(_), do: nil

  defp get_hierarchy_node(key) when is_binary(key) do
    case HierarchyCache.get_node!(key) do
      %{"name" => name} ->
        %{id: key, name: name}

      nil ->
        nil
    end
  end

  defp get_total(value) when is_integer(value), do: value
  defp get_total(%{"relation" => "eq", "value" => value}) when is_integer(value), do: value
end
