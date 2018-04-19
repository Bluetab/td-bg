defmodule TdBgWeb.DataDomainController do
  use TdBgWeb, :controller
  use TdBg.Hypermedia, :controller
  use PhoenixSwagger

  import Plug.Conn
  import Canada
  alias TdBgWeb.ErrorView
  alias TdBgWeb.UserView
  alias TdBg.Taxonomies
  alias TdBg.Permissions
  alias TdBg.Taxonomies.DataDomain
  alias TdBgWeb.SwaggerDefinitions
  alias Guardian.Plug, as: GuardianPlug

  action_fallback TdBgWeb.FallbackController

  plug :load_canary_action, phoenix_action: :create, canary_action: :create_data_domain
  plug :load_and_authorize_resource, model: DataDomain, id_name: "id", persisted: true, only: [:update, :delete, :create]

  @td_auth_api Application.get_env(:td_bg, :auth_service)[:api_service]
  @search_service Application.get_env(:td_bg, :elasticsearch)[:search_service]

  def swagger_definitions do
    SwaggerDefinitions.data_domain_swagger_definitions()
  end

  swagger_path :index do
    get "/data_domains"
    description "List Data Domains"
    response 200, "OK", Schema.ref(:DataDomainsResponse)
  end

  def index(conn, _params) do
    data_domains = Taxonomies.list_data_domains()
    render(conn, "index.json",
      data_domains: data_domains,
      hypermedia: hypermedia("data_domain", conn, data_domains))
  end

  swagger_path :index_children_data_domain do
    get "/domain_groups/{domain_group_id}/data_domains"
    description "List Data Domain children of Domain Group"
    produces "application/json"
    parameters do
      domain_group_id :path, :integer, "Domain Group ID", required: true
    end
    response 200, "OK", Schema.ref(:DataDomainsResponse)
    response 400, "Client Error"
  end

  def index_children_data_domain(conn, %{"domain_group_id" => id}) do
    data_domains = Taxonomies.list_children_data_domain(id)
    render(conn, "index.json",
      data_domains: data_domains,
      hypermedia: hypermedia("data_domain", conn, data_domains))
  end

  swagger_path :create do
    post "/data_domains"
    description "Creates a Data Domain child of Domain Group"
    produces "application/json"
    parameters do
      data_domain :body, Schema.ref(:DataDomainCreate), "Data Domain create attrs"
    end
    response 201, "Created", Schema.ref(:DataDomainResponse)
    response 400, "Client Error"
  end

  def create(conn, %{"data_domain" => data_domain_params}) do
    current_user = GuardianPlug.current_resource(conn)
    domain_group = Taxonomies.get_domain_group!(data_domain_params["domain_group_id"])

    if can?(current_user, create_data_domain(domain_group)) do
      do_create(conn, data_domain_params)
    else
      conn
      |> put_status(403)
      |> render(ErrorView, :"403")
    end

  end

  defp do_create(conn, data_domain_params) do
    case Taxonomies.create_data_domain(data_domain_params) do
      {:ok, %DataDomain{} = data_domain} ->
        conn = conn
        |> put_status(:created)
        |> put_resp_header("location", data_domain_path(conn, :show, data_domain))
        |> render("show.json", data_domain: data_domain)
        @search_service.put_search(data_domain)
        conn
      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(TdBgWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end

  swagger_path :show do
    get "/data_domains/{id}"
    description "Show Data Domain"
    produces "application/json"
    parameters do
      id :path, :integer, "Data Domain ID", required: true
    end
    response 200, "OK", Schema.ref(:DataDomainResponse)
    response 400, "Client Error"
  end

  def show(conn, %{"id" => id}) do
    data_domain = Taxonomies.get_data_domain!(id)
    render(conn, "show.json",
      data_domain: data_domain,
      hypermedia: hypermedia("data_domain", conn, data_domain))
  end

  swagger_path :update do
    put "/data_domains/{id}"
    description "Updates Data Domain"
    produces "application/json"
    parameters do
      data_domain :body, Schema.ref(:DataDomainUpdate), "Data Domain update attrs"
      id :path, :integer, "Data Domain ID", required: true
    end
    response 200, "OK", Schema.ref(:DataDomainResponse)
    response 400, "Client Error"
  end

  def update(conn, %{"id" => id, "data_domain" => data_domain_params}) do
    data_domain = Taxonomies.get_data_domain!(id)

    with {:ok, %DataDomain{} = data_domain} <- Taxonomies.update_data_domain(data_domain, data_domain_params) do
      @search_service.put_search(data_domain)
      render(conn, "show.json", data_domain: data_domain)
    end
  end

  swagger_path :delete do
    delete "/data_domains/{id}"
    description "Delete Data Domain"
    produces "application/json"
    parameters do
      id :path, :integer, "Data Domain ID", required: true
    end
    response 204, "OK"
    response 400, "Client Error"
  end

  def delete(conn, %{"id" => id}) do
    data_domain = Taxonomies.get_data_domain!(id)
    with {:count, :business_concept, 0} <- Taxonomies.count_data_domain_business_concept_children(id),
         {:ok, %DataDomain{}} <- Taxonomies.delete_data_domain(data_domain) do
      @search_service.delete_search(data_domain)
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

  swagger_path :users_roles do
    get "/data_domains/{data_domain_id}/users_roles"
    description "Lists user-role list of a data domain"
    produces "application/json"
    parameters do
      data_domain_id :path, :integer, "Data Domain ID", required: true
    end
    response 200, "Ok", Schema.ref(:UsersRolesResponse)
    response 400, "Client Error"
  end

  def users_roles(conn, %{"data_domain_id" => id}) do
    data_domain = Taxonomies.get_data_domain!(id)
    acl_entries = Permissions.list_acl_entries(%{data_domain: data_domain})
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

  swagger_path :available_users do
    get "/data_domains/{data_domain_id}/available_users"
    description "Lists users available in a data domain"
    produces "application/json"
    parameters do
      domain_group_id :path, :integer, "Data Domain ID", required: true
    end
    response 200, "Ok", Schema.ref(:UsersResponse)
    response 400, "Client Error"
  end
  def available_users(conn, %{"data_domain_id" => id}) do
    data_domain = Taxonomies.get_data_domain!(id)
    acl_entries = Permissions.list_acl_entries(%{data_domain: data_domain})
    role_user_id = Enum.map(acl_entries, fn(acl_entry) -> %{user_id: acl_entry.principal_id, role: acl_entry.role.name} end)
    all_users = @td_auth_api.index()
    available_users = Enum.filter(all_users, fn(user) -> Enum.find(role_user_id, &(&1.user_id == user.id)) == nil and user.is_admin == false end)
    render(conn, UserView, "index.json", users: available_users)
  end
end
