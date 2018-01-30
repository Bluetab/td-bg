defmodule TrueBGWeb.Taxonomy do
  @moduledoc false

  alias Poison, as: JSON
  import TrueBGWeb.Router.Helpers
  @endpoint TrueBGWeb.Endpoint
  @headers {"Content-type", "application/json"}

  def domain_group_create(token, name, description, parent_id \\ nil) do
    headers = [@headers, {"authorization", "Bearer #{token}"}]
    body = %{domain_group: %{name: name, description: description, parent_id: parent_id}} |> JSON.encode!
    %HTTPoison.Response{status_code: status_code, body: resp} =
        HTTPoison.post!(domain_group_url(@endpoint, :create), body, headers, [])
    {:ok, status_code, resp |> JSON.decode!}
  end

  def domain_group_list(token) do
    headers = [@headers, {"authorization", "Bearer #{token}"}]
    %HTTPoison.Response{status_code: status_code, body: resp} =
      HTTPoison.get!(domain_group_url(@endpoint, :index), headers, [])
    {:ok, status_code, resp |> JSON.decode!}
  end

  def domain_group_show(token, id) do
    headers = [@headers, {"authorization", "Bearer #{token}"}]
    %HTTPoison.Response{status_code: status_code, body: resp} =
      HTTPoison.get!(domain_group_url(@endpoint, :show, id), headers, [])
    {:ok, status_code, resp |> JSON.decode!}
  end

  def domain_group_update(token, id, name, description, parent_id \\ nil) do
    headers = [@headers, {"authorization", "Bearer #{token}"}]
    body = %{domain_group: %{name: name, description: description, parent_id: parent_id}} |> JSON.encode!
    %HTTPoison.Response{status_code: status_code, body: resp} =
        HTTPoison.patch!(domain_group_url(@endpoint, :update, id), body, headers, [])
    {:ok, status_code, resp |> JSON.decode!}
  end

  def data_domain_create(token, data_domain_params) do
    headers = [@headers, {"authorization", "Bearer #{token}"}]
    body = %{data_domain: data_domain_params} |> JSON.encode!
    %HTTPoison.Response{status_code: status_code, body: resp} =
      HTTPoison.post!(data_domain_url(@endpoint, :create), body, headers, [])
    {:ok, status_code, resp |> JSON.decode!}
  end

  def data_domain_update(token, id, name, description) do
    headers = [@headers, {"authorization", "Bearer #{token}"}]
    body = %{data_domain: %{name: name, description: description}} |> JSON.encode!
    %HTTPoison.Response{status_code: status_code, body: resp} =
      HTTPoison.patch!(data_domain_url(@endpoint, :update, id), body, headers, [])
    {:ok, status_code, resp |> JSON.decode!}
  end

  def data_domain_show(token, id) do
    headers = [@headers, {"authorization", "Bearer #{token}"}]
    %HTTPoison.Response{status_code: status_code, body: resp} =
      HTTPoison.get!(data_domain_url(@endpoint, :show, id), headers, [])
    {:ok, status_code, resp |> JSON.decode!}
  end

  def get_domain_droup_by_name(list, domain_group_name) do
    Enum.find(list, fn(domain_group) -> domain_group["name"] == domain_group_name end)
  end
end
