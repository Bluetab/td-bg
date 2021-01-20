defmodule TdBgWeb.Taxonomy do
  @moduledoc false

  alias TdBgWeb.Authentication
  alias TdBgWeb.Router.Helpers, as: Routes

  @endpoint TdBgWeb.Endpoint

  def domain_create(token, domain_params) do
    headers = Authentication.get_header(token)
    body = %{domain: domain_params} |> Jason.encode!()

    %HTTPoison.Response{status_code: status_code, body: resp} =
      HTTPoison.post!(Routes.domain_url(@endpoint, :create), body, headers, [])

    {:ok, status_code, resp |> Jason.decode!()}
  end

  def domain_list(token) do
    headers = Authentication.get_header(token)

    %HTTPoison.Response{status_code: status_code, body: resp} =
      HTTPoison.get!(Routes.domain_url(@endpoint, :index), headers, [])

    {:ok, status_code, resp |> Jason.decode!()}
  end

  def domain_show(token, id) do
    headers = Authentication.get_header(token)

    %HTTPoison.Response{status_code: status_code, body: resp} =
      HTTPoison.get!(Routes.domain_url(@endpoint, :show, id), headers, [])

    {:ok, status_code, resp |> Jason.decode!()}
  end

  def domain_update(token, id, domain_params) do
    headers = Authentication.get_header(token)
    body = %{domain: domain_params} |> Jason.encode!()

    %HTTPoison.Response{status_code: status_code, body: resp} =
      HTTPoison.patch!(Routes.domain_url(@endpoint, :update, id), body, headers, [])

    {:ok, status_code, resp |> Jason.decode!()}
  end

  def domain_delete(token, id) do
    headers = Authentication.get_header(token)

    %HTTPoison.Response{status_code: status_code, body: resp} =
      HTTPoison.delete!(Routes.domain_url(@endpoint, :delete, id), headers, [])

    case resp do
      "" -> {:ok, status_code, ""}
      resp -> {:ok, status_code, resp |> Jason.decode!()}
    end
  end

  def get_domain_by_name(token, domain_name) do
    {:ok, _status_code, json_resp} = domain_list(token)
    Enum.find(json_resp["data"], fn domain -> domain["name"] == domain_name end)
  end

  def get_domain_by_name_and_parent(token, domain_name, parent_id) do
    {:ok, _status_code, json_resp} = domain_list(token)

    Enum.find(json_resp["data"], fn domain ->
      domain["name"] == domain_name &&
        domain["parent_id"] == parent_id
    end)
  end

  def remove_tree_keys(nil), do: nil

  def remove_tree_keys(tree) do
    Enum.map(tree, fn node ->
      %{
        "name" => node["name"],
        "type" => node["type"],
        "description" => node["description"],
        "children" => remove_tree_keys(node["children"])
      }
    end)
  end
end
