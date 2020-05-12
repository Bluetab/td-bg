defmodule TdBgWeb.DomainController do
  use TdBgWeb, :controller
  use TdHypermedia, :controller
  use PhoenixSwagger

  import Canada, only: [can?: 2]

  alias TdBg.Taxonomies
  alias TdBg.Taxonomies.Domain
  alias TdBgWeb.SwaggerDefinitions

  action_fallback(TdBgWeb.FallbackController)

  def swagger_definitions do
    SwaggerDefinitions.domain_swagger_definitions()
  end

  swagger_path :index do
    description("List Domains")

    parameters do
      actions(:query, :string, "List of actions the user must be able to run over the domains",
        required: false
      )
    end

    response(200, "OK", Schema.ref(:DomainsResponse))
  end

  def index(conn, params) do
    user = conn.assigns[:current_user]
    domains = Taxonomies.list_domains()

    case get_actions(params) do
      [] ->
        domains = Enum.filter(domains, &can?(user, show(&1)))

        render(conn, "index.json",
          domains: domains,
          hypermedia: hypermedia("domain", conn, domains)
        )

      actions ->
        filtered_domains = Enum.filter(domains, &can_any?(actions, user, &1))
        render(conn, "index_tiny.json", domains: filtered_domains)
    end
  end

  defp can_any?(actions, user, domain) do
    alias Canada.Can

    actions
    |> Enum.map(&String.to_atom/1)
    |> Enum.any?(&Can.can?(user, &1, domain))
  end

  defp get_actions(params) do
    params
    |> Map.get("actions", "")
    |> String.split(",")
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
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

    with %Domain{} = domain <- Taxonomies.apply_changes(Domain, domain_params),
         {:can, true} <- {:can, can?(current_user, create(domain))},
         {:ok, %Domain{} = domain} <- Taxonomies.create_domain(domain_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", Routes.domain_path(conn, :show, domain))
      |> render("show.json", domain: domain)
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

    with domain <- Taxonomies.get_domain!(id),
         {:can, true} <- {:can, can?(current_user, show(domain))},
         parentable_ids <- Taxonomies.get_parentable_ids(current_user, domain) do
      render(conn, "show.json",
        domain: domain,
        parentable_ids: parentable_ids,
        hypermedia: hypermedia("domain", conn, domain)
      )
    end
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

    with {:ok, domain} <- Taxonomies.get_domain(id),
         {:can, true} <- {:can, can_update?(current_user, domain, domain_params)},
         {:ok, %Domain{} = updated_domain} <- Taxonomies.update_domain(domain, domain_params) do
      render(conn, "show.json", domain: updated_domain)
    end
  end

  defp can_update?(current_user, %{parent_id: id} = domain, %{parent_id: id} = _new_domain) do
    can?(current_user, update(domain))
  end

  defp can_update?(current_user, %{parent_id: _} = domain, %{parent_id: _} = new_domain) do
    # Changing parent_id requires delete/update permission on existing domain
    # and create permission on new domain
    Enum.all?([
      can?(current_user, move(domain)),
      can?(current_user, create(new_domain))
    ])
  end

  defp can_update?(current_user, %Domain{} = domain, %{} = params) do
    new_domain = Taxonomies.apply_changes(domain, params)
    can_update?(current_user, domain, new_domain)
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

    with {:ok, domain} <- Taxonomies.get_domain(id),
         {:can, true} <- {:can, can?(current_user, delete(domain))},
         {:ok, %Domain{}} <- Taxonomies.delete_domain(domain) do
      send_resp(conn, :no_content, "")
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

    with {:ok, domain} <- Taxonomies.get_domain(id),
         {:can, true} <- {:can, can?(current_user, show(domain))} do
      counter = Taxonomies.count_existing_users_with_roles(id, user_name)
      render(conn, "domain_bc_count.json", counter: counter)
    end
  end
end
