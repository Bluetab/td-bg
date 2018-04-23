defmodule TdBgWeb.DomainController do
  use TdBgWeb, :controller
  use TdBg.Hypermedia, :controller
  use PhoenixSwagger

  alias TdBgWeb.ErrorView
  alias TdBgWeb.UserView
  alias TdBg.Taxonomies
  alias TdBg.Permissions
  alias TdBg.Taxonomies.Domain
  alias TdBgWeb.SwaggerDefinitions
  alias TdBg.Utils.CollectionUtils
  alias Guardian.Plug, as: GuardianPlug
  import Canada

  action_fallback TdBgWeb.FallbackController

  plug :load_and_authorize_resource, model: Domain, id_name: "id", persisted: true, only: [:update, :delete]

  @td_auth_api Application.get_env(:td_bg, :auth_service)[:api_service]
  @search_service Application.get_env(:td_bg, :elasticsearch)[:search_service]

  def swagger_definitions do
    SwaggerDefinitions.domain_swagger_definitions()
  end

  swagger_path :index do
    get "/domains"
    description "List Domains"
    response 200, "OK", Schema.ref(:DomainsResponse)
  end

  def index(conn, _params) do
    domains = Taxonomies.list_domains()
    render(conn, "index.json",
      domains: domains,
      hypermedia: hypermedia("domain", conn, domains))
  end

  swagger_path :index_root do
    get "/domains/index_root"
    description "List Root Domain"
    produces "application/json"
    response 200, "OK", Schema.ref(:DomainsResponse)
    response 400, "Client Error"
  end

  def index_root(conn, _params) do
    domains = Taxonomies.list_root_domains()
    render(conn, "index.json",
      domains: domains,
      hypermedia: hypermedia("domain", conn, domains))
  end

  swagger_path :index_children do
    get "/domains/{domain_id}/index_children"
    description "List non-root Domains"
    produces "application/json"
    parameters do
      domain_id :path, :integer, "Domain ID", required: true
    end
    response 200, "OK", Schema.ref(:DomainsResponse)
    response 400, "Client Error"
  end

  def index_children(conn, %{"domain_id" => id}) do
    domains = Taxonomies.list_domain_children(id)
    render(conn, "index.json",
      domains: domains,
      hypermedia: hypermedia("domain", conn, domains))
  end

  swagger_path :create do
    post "/domains"
    description "Creates a Domain"
    produces "application/json"
    parameters do
      domain :body, Schema.ref(:DomainCreate), "Domain create attrs"
    end
    response 201, "Created", Schema.ref(:DomainResponse)
    response 400, "Client Error"
  end

  def create(conn, %{"domain" => domain_params}) do
    current_user = GuardianPlug.current_resource(conn)
    domain = %Domain{} |> Map.merge(CollectionUtils.to_struct(Domain, domain_params))

    if can?(current_user, create(domain)) do
      do_create(conn, domain_params)
    else
      conn
      |> put_status(403)
      |> render(ErrorView, :"403")
    end
  end

  defp do_create(conn, domain_params) do
    parent_id = Taxonomies.get_parent_id(domain_params)
    status = case parent_id do
      {:ok, _parent} -> Taxonomies.create_domain(domain_params)
      {:error, _} -> {:error, nil}
    end
    case status do
      {:ok, %Domain{} = domain} ->
        conn = conn
        |> put_status(:created)
        |> put_resp_header("location", domain_path(conn, :show, domain))
        |> render("show.json", domain: domain)
        @search_service.put_search(domain)
        conn
      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(TdBgWeb.ChangesetView, "error.json", changeset: changeset)
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

  swagger_path :show do
    get "/domains/{id}"
    description "Show Domain"
    produces "application/json"
    parameters do
      id :path, :integer, "Domain ID", required: true
    end
    response 200, "OK", Schema.ref(:DomainResponse)
    response 400, "Client Error"
  end

  def show(conn, %{"id" => id}) do
    domain = Taxonomies.get_domain!(id)
    render(conn, "show.json",
      domain: domain,
      hypermedia: hypermedia("domain", conn, domain))
  end

  swagger_path :update do
    put "/domains/{id}"
    description "Updates Domain"
    produces "application/json"
    parameters do
      data_domain :body, Schema.ref(:DomainUpdate), "Domain update attrs"
      id :path, :integer, "Domain ID", required: true
    end
    response 200, "OK", Schema.ref(:DomainResponse)
    response 400, "Client Error"
  end

  def update(conn, %{"id" => id, "domain" => domain_params}) do
    domain = Taxonomies.get_domain!(id)

    with {:ok, %Domain{} = domain} <- Taxonomies.update_domain(domain, domain_params) do
      @search_service.put_search(domain)
      render(conn, "show.json", domain: domain)
    end
  end

  swagger_path :delete do
    delete "/domains/{id}"
    description "Delete Domain"
    produces "application/json"
    parameters do
      id :path, :integer, "Domain ID", required: true
    end
    response 200, "OK"
    response 400, "Client Error"
  end

  def delete(conn, %{"id" => id}) do
    domain = Taxonomies.get_domain!(id)
    with {:count, :domain, 0} <- Taxonomies.count_domain_children(id),
         {:count, :business_concept, 0} <- Taxonomies.count_domain_business_concept_children(id),
         {:ok, %Domain{}} <- Taxonomies.delete_domain(domain) do
      @search_service.delete_search(domain)
      send_resp(conn, :no_content, "")
    else
      {:count, :domain, n}  when is_integer(n) ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ErrorView, :"422.json")
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

  swagger_path :available_users do
    get "/domains/{domain_id}/available_users"
    description "Lists users available in a domain group"
    produces "application/json"
    parameters do
      domain_id :path, :integer, "Domain ID", required: true
    end
    response 200, "Ok", Schema.ref(:UsersResponse)
    response 400, "Client Error"
  end

  def available_users(conn, %{"domain_id" => id}) do
    domain = Taxonomies.get_domain!(id)
    acl_entries = Permissions.list_acl_entries(%{domain: domain})
    role_user_id = Enum.map(acl_entries, fn(acl_entry) -> %{user_id: acl_entry.principal_id, role: acl_entry.role.name} end)
    all_users = @td_auth_api.index()
    available_users = Enum.filter(all_users, fn(user) -> Enum.find(role_user_id, &(&1.user_id == user.id)) == nil and user.is_admin == false end)
    render(conn, UserView, "index.json", users: available_users)
  end

  swagger_path :users_roles do
    get "/domains/{domain_id}/users_roles"
    description "Lists user-role list of a domain group"
    produces "application/json"
    parameters do
      domain_id :path, :integer, "Domain ID", required: true
    end
    response 200, "Ok", Schema.ref(:UsersRolesResponse)
    response 400, "Client Error"
  end

  def users_roles(conn, %{"domain_id" => id}) do
    domain = Taxonomies.get_domain!(id)
    acl_entries = Permissions.list_acl_entries(%{domain: domain})
    role_user_id = Enum.map(acl_entries, fn(acl_entry) -> %{user_id: acl_entry.principal_id, acl_entry_id: acl_entry.id, role_id: acl_entry.role.id, role_name: acl_entry.role.name} end)
    user_ids = Enum.reduce(role_user_id, [], fn(e, acc) -> acc ++ [e.user_id] end)
    users = @td_auth_api.search(%{"ids" => user_ids})
    users_roles = Enum.reduce(role_user_id, [],
      fn(u, acc) ->
        user = Enum.find(users, fn(r_u) -> r_u.id == u.user_id end)
        if user do
          acc ++ [Map.merge(%{role_id: u.role_id, role_name: u.role_name, acl_entry_id: u.acl_entry_id}, user_map(user))]
        else
          acc
        end
    end)
    render(conn, "index_user_roles.json",
      users_roles: users_roles,
      hypermedia: hypermedia("users_roles", conn, users_roles))
  end
  defp user_map(user) do
    %{"user_id": user.id, "user_name": user.user_name}
  end

end
