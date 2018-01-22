defmodule TrueBGWeb.DomainGroupController do
  use TrueBGWeb, :controller

  alias TrueBG.Taxonomies
  alias TrueBG.Taxonomies.DomainGroup

  action_fallback TrueBGWeb.FallbackController

  def index(conn, _params) do
    domain_groups = Taxonomies.list_domain_groups()
    render(conn, "index.json", domain_groups: domain_groups)
  end

  def create(conn, %{"domain_group" => domain_group_params}) do
    with {:ok, %DomainGroup{} = domain_group} <- Taxonomies.create_domain_group(domain_group_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", domain_group_path(conn, :show, domain_group))
      |> render("show.json", domain_group: domain_group)
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
