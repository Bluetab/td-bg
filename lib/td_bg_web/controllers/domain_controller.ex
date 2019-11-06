defmodule TdBgWeb.DomainController do
  use TdBgWeb, :controller
  use PhoenixSwagger

  import Canada, only: [can?: 2]

  alias Canada.Can
  alias TdBg.Taxonomies
  alias TdBg.Taxonomies.Domain
  alias TdBg.Utils.CollectionUtils
  alias TdBgWeb.ErrorView
  alias TdBgWeb.SwaggerDefinitions
  alias TdBgWeb.TaxonomySupport

  action_fallback(TdBgWeb.FallbackController)

  def swagger_definitions do
    SwaggerDefinitions.domain_swagger_definitions()
  end

  def options(conn, _params) do
    current_user = conn.assigns.current_user

    allowed_methods =
      [
        ["OPTIONS", true],
        ["GET", can?(current_user, list(Domain))],
        ["POST", can?(current_user, create(Domain))]
      ]
      |> Enum.filter(fn [_k, v] -> v end)
      |> Enum.map(fn [k, _v] -> k end)
      |> Enum.join(", ")

    conn
    |> put_resp_header("allow", allowed_methods)
    |> send_resp(:no_content, "")
  end

  swagger_path :index do
    description("List Domains")

    parameters do
      actions(
        :query,
        :string,
        "List of actions the user must be able to run over the domains",
        required: false
      )
    end

    response(200, "OK", Schema.ref(:DomainsResponse))
  end

  def index(conn, params) do
    user = conn.assigns[:current_user]
    domains = Taxonomies.list_domains()

    case params |> get_actions do
      [] ->
        domains = Enum.filter(domains, &can?(user, show(&1)))

        conn
        |> put_hypermedia("domains", domains: domains, resource_type: Domain)
        |> render("index.json")

      actions ->
        filtered_domains = Enum.filter(domains, &can_any?(actions, user, &1))

        render(
          conn,
          "index_tiny.json",
          domains: filtered_domains,
          resource_type: Domain
        )
    end
  end

  defp can_any?(actions, user, domain) do
    Enum.find(actions, nil, &Can.can?(user, String.to_atom(&1), domain)) != nil
  end

  defp get_actions(params) do
    params
    |> Map.get("actions", "")
    |> String.split(",")
    |> Enum.map(&String.trim(&1))
    |> Enum.filter(&(&1 !== ""))
  end

  swagger_path :create do
    description("Creates a Domain")
    produces("application/json")

    parameters do
      domain(:body, Schema.ref(:DomainCreate), "Domain create attrs")
    end

    response(201, "Created", Schema.ref(:DomainResponse))
    response(400, "Client Error")
  end

  def create(conn, %{"domain" => domain_params}) do
    current_user = conn.assigns[:current_user]
    domain = %Domain{} |> Map.merge(CollectionUtils.to_struct(Domain, domain_params))

    domain_parent =
      case Map.has_key?(domain_params, "parent_id") do
        false -> domain
        true -> Taxonomies.get_domain!(domain_params["parent_id"])
      end

    if can?(current_user, create(domain_parent)) do
      do_create(conn, domain_params)
    else
      conn
      |> put_status(:forbidden)
      |> put_view(ErrorView)
      |> render("403.json")
    end
  end

  defp do_create(conn, domain_params) do
    parent_id = Taxonomies.get_parent_id(domain_params)

    status =
      case parent_id do
        {:ok, _parent} -> Taxonomies.create_domain(domain_params)
        {:error, _} -> {:error, nil}
      end

    case status do
      {:ok, %Domain{} = domain} ->
        conn =
          conn
          |> put_status(:created)
          |> put_resp_header("location", Routes.domain_path(conn, :show, domain))
          |> render("show.json", domain: domain)

        conn

      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> put_view(TdBgWeb.ChangesetView)
        |> render("error.json", changeset: changeset)

      {:error, nil} ->
        conn
        |> put_status(:not_found)
        |> put_view(ErrorView)
        |> render("404.json")

      _ ->
        conn
        |> put_status(:internal_server_error)
        |> put_view(ErrorView)
        |> render("500.json")
    end
  end

  swagger_path :show do
    description("Show Domain")
    produces("application/json")

    parameters do
      id(:path, :integer, "Domain ID", required: true)
    end

    response(200, "OK", Schema.ref(:DomainResponse))
    response(400, "Client Error")
  end

  def show(conn, %{"id" => id}) do
    current_user = conn.assigns[:current_user]
    domain = Taxonomies.get_domain!(id)

    if can?(current_user, show(domain)) do
      do_show(conn, domain)
    else
      conn
      |> put_status(:forbidden)
      |> put_view(ErrorView)
      |> render("403.json")
    end
  end

  defp do_show(conn, domain) do
    conn
    |> put_hypermedia("domains", domain: domain)
    |> render("show.json")
  end

  swagger_path :update do
    description("Updates Domain")
    produces("application/json")

    parameters do
      data_domain(:body, Schema.ref(:DomainUpdate), "Domain update attrs")
      id(:path, :integer, "Domain ID", required: true)
    end

    response(200, "OK", Schema.ref(:DomainResponse))
    response(400, "Client Error")
  end

  def update(conn, %{"id" => id, "domain" => domain_params}) do
    current_user = conn.assigns[:current_user]
    domain = Taxonomies.get_domain!(id)

    if can?(current_user, update(domain)) do
      do_update(conn, domain, domain_params)
    else
      conn
      |> put_status(:forbidden)
      |> put_view(ErrorView)
      |> render("403.json")
    end
  end

  defp do_update(conn, domain, domain_params) do
    with {:ok, %Domain{} = updated_domain} <- Taxonomies.update_domain(domain, domain_params) do
      render(conn, "show.json", domain: updated_domain)
    end
  end

  swagger_path :delete do
    description("Delete Domain")
    produces("application/json")

    parameters do
      id(:path, :integer, "Domain ID", required: true)
    end

    response(200, "OK")
    response(400, "Client Error")
  end

  def delete(conn, %{"id" => id}) do
    current_user = conn.assigns[:current_user]
    domain = Taxonomies.get_domain!(id)

    if can?(current_user, delete(domain)) do
      do_delete(conn, domain)
    else
      conn
      |> put_status(:forbidden)
      |> put_view(ErrorView)
      |> render("403.json")
    end
  end

  defp do_delete(conn, domain) do
    with {:ok, %Domain{}} <- Taxonomies.delete_domain(domain) do
      send_resp(conn, :no_content, "")
    else
      error ->
        TaxonomySupport.handle_taxonomy_errors_on_delete(conn, error)
    end
  end

  swagger_path :count_bc_in_domain_for_user do
    description(
      "Counts the number of Business Concepts where the given user has any role in the provided domain"
    )

    produces("application/json")

    parameters do
      id(:path, :integer, "Domain ID", required: true)
      user_name(:path, :integer, "User Name", required: true)
    end

    response(200, "OK", Schema.ref(:BCInDomainCountResponse))
    response(400, "Client Error")
  end

  def count_bc_in_domain_for_user(conn, %{"domain_id" => id, "user_name" => user_name}) do
    current_user = conn.assigns[:current_user]
    domain = Taxonomies.get_domain!(id)

    if can?(current_user, show(domain)) do
      counter = id |> Taxonomies.count_existing_users_with_roles(user_name)
      render(conn, "domain_bc_count.json", counter: counter)
    else
      conn
      |> put_status(:forbidden)
      |> put_view(ErrorView)
      |> render("403.json")
    end
  end
end
