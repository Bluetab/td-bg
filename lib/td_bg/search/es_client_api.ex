defmodule TdBg.ESClientApi do
  use HTTPoison.Base

  alias Jason, as: JSON

  require Logger

  @moduledoc false

  @doc """
  Loads all index configuration into elasticsearch
  """
  def create_indexes do
    json = File.read!(Path.join(:code.priv_dir(:td_bg), "static/indexes.json"))
    json_decode = json |> JSON.decode!()

    Enum.map(json_decode, fn x ->
      index_name = x |> Map.keys() |> List.first()
      mapping = x[index_name] |> JSON.encode!()
      %HTTPoison.Response{body: _response, status_code: status} = put!(index_name, mapping)
      Logger.info("Create index #{index_name} status #{status}")
    end)
  end

  def bulk_index_content(items) do
    json_bulk_data =
      items
      |> Enum.map(fn item ->
        [
          build_bulk_metadata(item.__struct__.index_name, item, :index),
          build_bulk_doc(item, :index)
        ]
      end)
      |> List.flatten()
      |> Enum.join("\n")

    post("_bulk", json_bulk_data <> "\n")
  end

  def bulk_update_content(items) do
    json_bulk_data =
      items
      |> Enum.map(fn item ->
        [
          build_bulk_metadata(item.__struct__.index_name, item, :update),
          build_bulk_doc(item, :update)
        ]
      end)
      |> List.flatten()
      |> Enum.join("\n")

    post("_bulk", json_bulk_data <> "\n")
  end

  def reindex(old_index, new_index) do
    post("_reindex", JSON.encode!(%{source: %{index: old_index}, dest: %{index: new_index}}))
  end

  defp build_bulk_doc(item, :index) do
    search_fields = item.__struct__.search_fields(item)
    "#{search_fields |> JSON.encode!()}"
  end

  defp build_bulk_doc(item, :update) do
    search_fields = item.__struct__.search_fields(item)
    ~s({"doc": #{search_fields |> JSON.encode!()}})
  end

  defp build_bulk_metadata(index_name, item, :index) do
    ~s({"index": {"_id": #{item.id}, "_type": "#{get_type_name()}", "_index": "#{index_name}"}})
  end

  defp build_bulk_metadata(index_name, item, :update) do
    ~s({"update": {"_id": #{item.id}, "_type": "#{get_type_name()}", "_index": "#{index_name}"}})
  end

  def index_content(index_name, id, body) do
    put(get_search_path(index_name, id), body)
  end

  def delete_content(index_name, id) do
    delete(get_search_path(index_name, id))
  end

  def search_es(index_name, query) do
    post("#{index_name}/" <> "_search/", query |> JSON.encode!())
  end

  defp get_type_name do
    Application.get_env(:td_bg, :elasticsearch)[:type_name]
  end

  defp get_search_path(index_name, id) do
    type_name = get_type_name()
    "#{index_name}/" <> "#{type_name}/" <> "#{id}"
  end

  @doc """
  Deletes all indexes in elasticsearch
  """
  def delete_indexes(options \\ []) do
    json = File.read!(Path.join(:code.priv_dir(:td_bg), "static/indexes.json"))
    json_decode = json |> JSON.decode!()

    Enum.map(json_decode, fn x ->
      index_name = x |> Map.keys() |> List.first()
      %HTTPoison.Response{body: _response, status_code: status} = delete!(index_name, options)
      Logger.info("Delete index #{index_name} status #{status}")
    end)
  end

  @doc """
  Concatenates elasticsearch path at the beggining of HTTPoison requests
  """
  def process_url(path) do
    es_config = Application.get_env(:td_bg, :elasticsearch)
    "#{es_config[:es_host]}:#{es_config[:es_port]}/" <> path
  end

  @doc """
  Set default request options (increase timeout for receiving HTTP response)
  """
  def process_request_options(options) do
    [recv_timeout: 20_000]
    |> Keyword.merge(options)
  end

  @doc """
    Decodes response body
  """
  def process_response_body(body) do
    body
    |> JSON.decode!()
  end

  @doc """
  Adds requests headers
  """
  def process_request_headers(_headers) do
    headers = [{"Content-Type", "application/json"}]
    headers
  end
end
