defmodule TdBGWeb.Taxonomy do
  @moduledoc false

  alias Poison, as: JSON
  import TdBGWeb.Router.Helpers
  import TdBGWeb.Authentication, only: :functions
  @endpoint TdBGWeb.Endpoint

  def domain_group_create(token, domain_group_params) do
    headers = get_header(token)
    body = %{domain_group: domain_group_params} |> JSON.encode!
    %HTTPoison.Response{status_code: status_code, body: resp} =
        HTTPoison.post!(domain_group_url(@endpoint, :create), body, headers, [])
    {:ok, status_code, resp |> JSON.decode!}
  end

  def domain_group_list(token) do
    headers = get_header(token)
    %HTTPoison.Response{status_code: status_code, body: resp} =
      HTTPoison.get!(domain_group_url(@endpoint, :index), headers, [])
    {:ok, status_code, resp |> JSON.decode!}
  end

  def domain_group_show(token, id) do
    headers = get_header(token)
    %HTTPoison.Response{status_code: status_code, body: resp} =
      HTTPoison.get!(domain_group_url(@endpoint, :show, id), headers, [])
    {:ok, status_code, resp |> JSON.decode!}
  end

  def domain_group_update(token, id, domain_group_params) do
    headers = get_header(token)
    body = %{domain_group: domain_group_params} |> JSON.encode!
    %HTTPoison.Response{status_code: status_code, body: resp} =
        HTTPoison.patch!(domain_group_url(@endpoint, :update, id), body, headers, [])
    {:ok, status_code, resp |> JSON.decode!}
  end

  def domain_group_delete(token, id) do
    headers = get_header(token)
    %HTTPoison.Response{status_code: status_code} =
        HTTPoison.delete!(domain_group_url(@endpoint, :delete , id), headers, [])
    {:ok, status_code}
  end

  def data_domain_create(token, data_domain_params) do
    headers = get_header(token)
    body = %{data_domain: data_domain_params} |> JSON.encode!
    domain_group_id = data_domain_params[:domain_group_id]
    %HTTPoison.Response{status_code: status_code, body: resp} =
      HTTPoison.post!(domain_group_data_domain_url(@endpoint, :create, domain_group_id), body, headers, [])
    {:ok, status_code, resp |> JSON.decode!}
  end

  def data_domain_update(token, id, data_domain_params) do
    headers = get_header(token)
    body = %{data_domain: data_domain_params} |> JSON.encode!
    %HTTPoison.Response{status_code: status_code, body: resp} =
      HTTPoison.patch!(data_domain_url(@endpoint, :update, id), body, headers, [])
    {:ok, status_code, resp |> JSON.decode!}
  end

  def data_domain_show(token, id) do
    headers = get_header(token)
    %HTTPoison.Response{status_code: status_code, body: resp} =
      HTTPoison.get!(data_domain_url(@endpoint, :show, id), headers, [])
    {:ok, status_code, resp |> JSON.decode!}
  end

  def data_domain_list(token) do
    headers = get_header(token)
    %HTTPoison.Response{status_code: status_code, body: resp} =
      HTTPoison.get!(data_domain_url(@endpoint, :index), headers, [])
    {:ok, status_code, resp |> JSON.decode!}
  end

  def data_domain_delete(token, id) do
    headers = get_header(token)
    %HTTPoison.Response{status_code: status_code} =
        HTTPoison.delete!(data_domain_url(@endpoint, :delete , id), headers, [])
    {:ok, status_code}
  end

  def get_domain_group_by_name(token, domain_group_name) do
    {:ok, _status_code, json_resp} = domain_group_list(token)
    Enum.find(json_resp["data"], fn(domain_group) -> domain_group["name"] == domain_group_name end)
  end

  def get_domain_group_by_name_and_parent(token, domain_group_name, parent_id) do
    {:ok, _status_code, json_resp} = domain_group_list(token)
    Enum.find(json_resp["data"], fn(domain_group) ->
                                      domain_group["name"] == domain_group_name &&
                                      domain_group["parent_id"] == parent_id
                                  end)
  end

  def get_data_domain_by_name(token, data_domain_name) do
    {:ok, _status_code, json_resp} = data_domain_list(token)
    Enum.find(json_resp["data"], fn(data_domain) -> data_domain["name"] == data_domain_name end)
  end

  def get_data_domain_by_name_and_parent(token, data_domain_name, domain_group_id) do
    {:ok, _status_code, json_resp} = data_domain_list(token)
    Enum.find(json_resp["data"], fn(data_domain) ->
        data_domain["name"] == data_domain_name &&
        data_domain["domain_group_id"] == domain_group_id
      end)
  end

end
