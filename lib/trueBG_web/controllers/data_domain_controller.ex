defmodule TrueBGWeb.DataDomainController do
  use TrueBGWeb, :controller

  import Plug.Conn
  alias TrueBGWeb.ErrorView
  alias TrueBG.Taxonomies
  alias TrueBG.Taxonomies.DataDomain
  alias TrueBG.Taxonomies.DomainGroup

  action_fallback TrueBGWeb.FallbackController

  plug :load_canary_action, phoenix_action: :create, canary_action: :create_data_domain
  plug :load_and_authorize_resource, model: DomainGroup, id_name: "domain_group_id", persisted: true, only: :create_data_domain

  def index(conn, _params) do
    data_domains = Taxonomies.list_data_domains()
    render(conn, "index.json", data_domains: data_domains)
  end

  def index_children_data_domain(conn, %{"domain_group_id" => id}) do
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
    with {:count, :business_concept, 0} <- Taxonomies.count_data_domain_business_concept_children(id),
         {:ok, %DataDomain{}} <- Taxonomies.delete_data_domain(data_domain) do
      send_resp(conn, :no_content, "")
    else
      {:count, :business_concept, n}  when is_integer(n) ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ErrorView, :"422.json")
      _error ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ErrorView, :"422.json")
    end
  end
end
