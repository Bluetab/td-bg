defmodule TrueBGWeb.DataDomainController do
  use TrueBGWeb, :controller

  import Plug.Conn
  alias TrueBG.Taxonomies
  alias TrueBG.Taxonomies.DataDomain
  alias TrueBGWeb.ErrorView

  plug :authorize_resource, model: DataDomain

  action_fallback TrueBGWeb.FallbackController

  def index(conn, _params) do
    if conn.assigns.authorized do
        data_domains = Taxonomies.list_data_domains()
        render(conn, "index.json", data_domains: data_domains)
    else
      conn
      |> put_status(:unauthorized)
      |> render(ErrorView, :"401.json")
    end
  end

  def index_children_data_domain(conn, %{"id" => id}) do
    data_domains = Taxonomies.list_children_data_domain(id)
    render(conn, "index.json", data_domains: data_domains)
  end

  def create(conn, %{"data_domain" => data_domain_params}) do
    with {:ok, %DataDomain{} = data_domain} <- Taxonomies.create_data_domain(data_domain_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", data_domain_path(conn, :show, data_domain))
      |> render("show.json", data_domain: data_domain)
    end
  end

  def show(conn, %{"id" => id}) do
    data_domain = Taxonomies.get_data_domain!(id)
    render(conn, "show.json", data_domain: data_domain)
  end

  def update(conn, %{"id" => id, "data_domain" => data_domain_params}) do
    data_domain = Taxonomies.get_data_domain!(id)

    with {:ok, %DataDomain{} = data_domain} <- Taxonomies.update_data_domain(data_domain, data_domain_params) do
      render(conn, "show.json", data_domain: data_domain)
    end
  end

  def delete(conn, %{"id" => id}) do
    data_domain = Taxonomies.get_data_domain!(id)
    with {:ok, %DataDomain{}} <- Taxonomies.delete_data_domain(data_domain) do
      send_resp(conn, :no_content, "")
    end
  end
end
