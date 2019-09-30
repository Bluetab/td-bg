defmodule TdBg.ESClientApi do
  use HTTPoison.Base

  alias Jason, as: JSON

  require Logger

  @moduledoc false

  def reindex(old_index, new_index) do
    post("_reindex", JSON.encode!(%{source: %{index: old_index}, dest: %{index: new_index}}))
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
