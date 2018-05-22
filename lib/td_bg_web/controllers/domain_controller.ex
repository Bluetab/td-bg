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
  alias TdBg.Permissions.AclEntry
  import Canada

  action_fallback TdBgWeb.FallbackController

  plug :load_and_authorize_resource, model: Domain, id_name: "id", persisted: true, only: [:update, :delete]

  @td_auth_api Application.get_env(:td_bg, :auth_service)[:api_service]
  @search_service Application.get_env(:td_bg, :elasticsearch)[:search_service]

  def swagger_definitions do
    SwaggerDefinitions.domain_swagger_definitions()
  end

  def options(conn, _params) do
    current_user = conn.assigns.current_user

    allowed_methods = [
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

    domain_parent = case Map.has_key?(domain_params, "parent_id") do
      false -> domain
      true -> Taxonomies.get_domain!(domain_params["parent_id"])
    end

    if can?(current_user, create(domain_parent)) do
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

  swagger_path :acl_entries do
    get "/domains/{domain_id}/acl_entries"
    description "Lists user-role list of a domain group"
    produces "application/json"
    parameters do
      domain_id :path, :integer, "Domain ID", required: true
    end
    response 200, "Ok", Schema.ref(:DomainAclEntriesResponse)
    response 400, "Client Error"
  end

  def acl_entries(conn, %{"domain_id" => id}) do
    domain = Taxonomies.get_domain!(id)
    acl_entries = Permissions.get_list_acl_from_domain(domain)
    render(conn, "index_acl_entries.json",
      acl_entries: acl_entries,
      hypermedia: hypermedia("acl_entries", conn, acl_entries))
  end

  swagger_path :create_acl_entry do
    post "/domains/{domain_id}/acl_entries"
    description "Creates an Acl Entry"
    produces "application/json"
    parameters do
      domain_id :path, :integer, "Domain ID", required: true
      acl_entry :body, Schema.ref(:DomainAclEntryCreate), "Acl entry create attrs"
    end
    response 201, "OK", Schema.ref(:DomainAclEntryResponse)
    response 400, "Client Error"
  end

  def create_acl_entry(conn, %{"domain_id" => id, "acl_entry" => acl_entry_params}) do
    acl_entry_params = Map.merge(%{"resource_id" => id, "resource_type" => "domain"}, acl_entry_params)
    acl_entry = %AclEntry{} |> Map.merge(CollectionUtils.to_struct(AclEntry, acl_entry_params))
    current_user = GuardianPlug.current_resource(conn)

    if current_user |> can?(create(acl_entry)) do
      with {:ok, %AclEntry{} = acl_entry} <- Permissions.create_acl_entry(acl_entry_params) do
        conn
        |> put_status(:created)
        |> render("acl_entry_show.json", acl_entry: acl_entry)
      else
        _error ->
          conn
          |> put_status(:unprocessable_entity)
          |> render(ErrorView, :"422.json")
      end
    else
      conn
      |> put_status(403)
      |> render(ErrorView, :"403")
    end
  end

end
