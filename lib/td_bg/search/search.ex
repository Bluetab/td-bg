defmodule TdBg.Search do
  use HTTPoison.Base
  require Logger

  @moduledoc false

  @doc """
  Loads all index configuration into elasticsearch
  """
  def create_indexes do
    json = File.read!(Path.join(:code.priv_dir(:td_bg), "static/indexes.json"))
    json_decode = json |> Poison.decode!
    Enum.map(json_decode, fn(x) ->
     index_name = x |> Map.keys |> List.first
     mapping = x[index_name] |> Poison.encode!
     %HTTPoison.Response{body: _response, status_code: status} =
       put!(index_name, mapping)
      Logger.info "Create index #{index_name} status #{status}"
    end)

  end

  def index_content(index_name, id, body) do
    %HTTPoison.Response{body: response, status_code: status} =
      put!(get_search_path(index_name, id), body)
  end

  def delete_content(index_name, id) do
    %HTTPoison.Response{body: response, status_code: status} =
      delete!(get_search_path(index_name, id))
  end

  defp get_search_path(index_name, id) do
    "#{index_name}/" <> "_doc/" <> "#{id}"
  end

  @doc """
  Deletes all indexes in elasticsearch
  """
  def delete_indexes(options \\ []) do
    json = File.read!(Path.join(:code.priv_dir(:td_bg), "static/indexes.json"))
    json_decode = json |> Poison.decode!
    Enum.map(json_decode, fn(x) ->
      index_name = x |> Map.keys |> List.first
      %HTTPoison.Response{body: _response, status_code: status} =
        delete!(index_name, options)
      Logger.info "Delete index #{index_name} status #{status}"
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
    Decodes response body
  """
  def process_response_body(body) do
    body
    |> Poison.decode!
  end

  @doc """
    Adds requests headers
  """
  def process_request_headers(_headers) do
    headers = [{"Content-Type", "application/json"}]
    headers
  end

end
