defmodule TrueBGWeb.DomainGroupController do
  use TrueBGWeb, :controller

  alias TrueBGWeb.ErrorView
  alias TrueBG.Taxonomies
  alias TrueBG.Taxonomies.DomainGroup

  action_fallback TrueBGWeb.FallbackController

  def index(conn, _params) do
    domain_groups = Taxonomies.list_domain_groups()
    render(conn, "index.json", domain_groups: domain_groups)
  end

  def index_root(conn, _params) do
    domain_groups = Taxonomies.list_root_domain_groups()
    render(conn, "index.json", domain_groups: domain_groups)
  end

  def index_children(conn, %{"id" => id}) do
    domain_groups = Taxonomies.list_domain_group_children(id)
    render(conn, "index.json", domain_groups: domain_groups)
  end

  def create(conn, %{"domain_group" => domain_group_params}) do
    parent_id = Taxonomies.get_parent_id(domain_group_params)
    status = case parent_id do
      {:ok, _parent} -> Taxonomies.create_domain_group(domain_group_params)
      {:error, _} -> {:error, nil}
    end

    case status do
      {:ok, %DomainGroup{} = domain_group} ->
        conn
        |> put_status(:created)
        |> put_resp_header("location", domain_group_path(conn, :show, domain_group))
        |> render("show.json", domain_group: domain_group)
      {:error, %Ecto.Changeset{} = _ecto_changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ErrorView, :"422.json")
      {:error, nil} ->
        conn
        |> put_status(:not_found)
        |> render(ErrorView, :"404.json")
      _ ->
        conn
        |> put_status(:internal_server_error)
        |> render(ErrorView, :"500.json")
    end
  end

  def show(conn, %{"id" => id}) do
    domain_group = Taxonomies.get_domain_group!(id)
    render(conn, "show.json", domain_group: domain_group)
  end

  def update(conn, %{"id" => id, "domain_group" => domain_group_params}) do
    domain_group = Taxonomies.get_domain_group!(id)

    with {:ok, %DomainGroup{} = domain_group} <- Taxonomies.update_domain_group(domain_group, domain_group_params) do
      render(conn, "show.json", domain_group: domain_group)
    end
  end

  def delete(conn, %{"id" => id}) do
    domain_group = Taxonomies.get_domain_group!(id)
    with {:ok, %DomainGroup{}} <- Taxonomies.delete_domain_group(domain_group) do
      send_resp(conn, :no_content, "")
    end
  end
end
