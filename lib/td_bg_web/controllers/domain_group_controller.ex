defmodule TdBgWeb.DomainGroupController do
  use TdBgWeb, :controller
  use PhoenixSwagger

  alias TdBgWeb.ErrorView
  alias TdBgWeb.UserView
  alias TdBg.Taxonomies
  alias TdBg.Permissions
  alias TdBg.Taxonomies.DomainGroup
  alias TdBg.Taxonomies.DataDomain
  alias TdBgWeb.SwaggerDefinitions
  alias TdBg.Utils.CollectionUtils
  alias Guardian.Plug, as: GuardianPlug
  alias Poison, as: JSON
  import Canada

  action_fallback TdBgWeb.FallbackController

  plug :load_and_authorize_resource, model: DomainGroup, id_name: "id", persisted: true, only: [:update, :delete]
  @td_auth_api Application.get_env(:td_bg, :auth_service)[:api_service]

  def swagger_definitions do
    SwaggerDefinitions.domain_group_swagger_definitions()
  end

  swagger_path :index do
    get "/domain_groups"
    description "List Domain Groups"
    response 200, "OK", Schema.ref(:DomainGroupsResponse)
  end

  def index(conn, _params) do
    domain_groups = Taxonomies.list_domain_groups()
    render(conn, "index.json", domain_groups: domain_groups)
  end

  swagger_path :index_root do
    get "/domain_groups/index_root"
    description "List Root Domain Group"
    produces "application/json"
    response 200, "OK", Schema.ref(:DomainGroupsResponse)
    response 400, "Client Error"
  end

  def index_root(conn, _params) do
    domain_groups = Taxonomies.list_root_domain_groups()
    render(conn, "index.json", domain_groups: domain_groups)
  end

  swagger_path :index_children do
    get "/domain_groups/{domain_group_id}/index_children"
    description "List non-root Domain Groups"
    produces "application/json"
    parameters do
      domain_group_id :path, :integer, "Domain Group ID", required: true
    end
    response 200, "OK", Schema.ref(:DomainGroupsResponse)
    response 400, "Client Error"
  end

  def index_children(conn, %{"domain_group_id" => id}) do
    domain_groups = Taxonomies.list_domain_group_children(id)
    render(conn, "index.json", domain_groups: domain_groups)
  end

  swagger_path :create do
    post "/domain_groups"
    description "Creates a Domain Group"
    produces "application/json"
    parameters do
      domain_group :body, Schema.ref(:DomainGroupCreate), "Domain Group create attrs"
    end
    response 201, "Created", Schema.ref(:DomainGroupResponse)
    response 400, "Client Error"
  end

  def create(conn, %{"domain_group" => domain_group_params}) do
    current_user = GuardianPlug.current_resource(conn)
    domain_group = %DomainGroup{} |> Map.merge(CollectionUtils.to_struct(DomainGroup, domain_group_params))

    if current_user |> can?(create(domain_group)) do
      do_create(conn, domain_group_params)
    else
      conn
      |> put_status(403)
      |> render(ErrorView, :"403")
    end
  end

  defp do_create(conn, domain_group_params) do
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

  swagger_path :show do
    get "/domain_groups/{id}"
    description "Show Domain Group"
    produces "application/json"
    parameters do
      id :path, :integer, "Domain Group ID", required: true
    end
    response 200, "OK", Schema.ref(:DomainGroupResponse)
    response 400, "Client Error"
  end

  def show(conn, %{"id" => id}) do
    domain_group = Taxonomies.get_domain_group!(id)
    render(conn, "show.json", domain_group: domain_group)
  end

  swagger_path :update do
    put "/domain_groups/{id}"
    description "Updates Domain Group"
    produces "application/json"
    parameters do
      data_domain :body, Schema.ref(:DomainGroupUpdate), "Domain Group update attrs"
      id :path, :integer, "Domain Group ID", required: true
    end
    response 200, "OK", Schema.ref(:DomainGroupResponse)
    response 400, "Client Error"
  end

  def update(conn, %{"id" => id, "domain_group" => domain_group_params}) do
    domain_group = Taxonomies.get_domain_group!(id)

    with {:ok, %DomainGroup{} = domain_group} <- Taxonomies.update_domain_group(domain_group, domain_group_params) do
      render(conn, "show.json", domain_group: domain_group)
    end
  end

  swagger_path :delete do
    delete "/domain_groups/{id}"
    description "Delete Domain Group"
    produces "application/json"
    parameters do
      id :path, :integer, "Domain Group ID", required: true
    end
    response 200, "OK"
    response 400, "Client Error"
  end

  def delete(conn, %{"id" => id}) do
    domain_group = Taxonomies.get_domain_group!(id)
    with {:count, :domain_group, 0} <- Taxonomies.count_domain_group_domain_group_children(id),
         {:count, :data_domain, 0} <- Taxonomies.count_domain_group_data_domain_children(id),
         {:ok, %DomainGroup{}} <- Taxonomies.delete_domain_group(domain_group) do
      send_resp(conn, :no_content, "")
    else
      {:count, :domain_group, n}  when is_integer(n) ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ErrorView, :"422.json")
      {:count, :data_domain, n}  when is_integer(n) ->
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
    get "/domain_groups/{domain_group_id}/available_users"
    description "Lists users available in a domain group"
    produces "application/json"
    parameters do
      domain_group_id :path, :integer, "Domain Group ID", required: true
    end
    response 200, "Ok", Schema.ref(:UsersResponse)
    response 400, "Client Error"
  end
  def available_users(conn, %{"domain_group_id" => id}) do
    domain_group = Taxonomies.get_domain_group!(id)
    acl_entries = Permissions.list_acl_entries(%{domain_group: domain_group})
    role_user_id = Enum.map(acl_entries, fn(acl_entry) -> %{user_id: acl_entry.principal_id, role: acl_entry.role.name} end)
    all_users = @td_auth_api.index()
    available_users = Enum.filter(all_users, fn(user) -> Enum.find(role_user_id, &(&1.user_id == user.id)) == nil and user.is_admin == false end)
    render(conn, UserView, "index.json", users: available_users)
  end

  swagger_path :users_roles do
    post "/domain_groups/{domain_group_id}/users_roles"
    description "Lists user-role list of a domain group"
    produces "application/json"
    parameters do
      domain_group_id :path, :integer, "Domain Group ID", required: true
    end
    response 200, "Ok", Schema.ref(:UsersRolesResponse)
    response 400, "Client Error"
  end
  def users_roles(conn, %{"domain_group_id" => id}) do
    domain_group = Taxonomies.get_domain_group!(id)
    acl_entries = Permissions.list_acl_entries(%{domain_group: domain_group})
    role_user_id = Enum.map(acl_entries, fn(acl_entry) -> %{user_id: acl_entry.principal_id, role_id: acl_entry.role.id, role_name: acl_entry.role.name} end)
    user_ids = Enum.reduce(role_user_id, [], fn(e, acc) -> acc ++ [e.user_id] end)
    users = @td_auth_api.search(%{"ids" => user_ids})
    users_roles = Enum.reduce(role_user_id, [],
      fn(u, acc) ->
        acc ++ [Map.merge(%{role_id: u.role_id, role_name: u.role_name}, user_map(Enum.find(users, &(&1.id == u.user_id))))]
    end)
    render(conn, "index_user_roles.json", users_roles: users_roles)
  end
  defp user_map(user) do
    %{"user_id": user.id, "user_name": user.user_name}
  end

  def tree(conn, _params) do
    dg_list = Taxonomies.list_root_domain_groups() |> Enum.sort(&(&1.name < &2.name))
    dg_all = Taxonomies.list_domain_groups() |> Enum.sort(&(&1.name < &2.name))
    dd_all = Taxonomies.list_data_domains() |> Enum.sort(&(&1.name < &2.name))
    out = Enum.map(dg_list, fn(dg) -> build_node(dg, dg_all, dd_all) end)
    json conn, out |> JSON.encode!
  end

  defp build_node(dg, dg_all, dd_all) do
    dg_map = build_map(dg)
    Map.merge(dg_map, %{children: list_children(dg_map, dg_all, dd_all)})
  end

  defp list_children(node, dg_all, dd_all) do
    dg_children = Enum.filter(dg_all, fn(dg) -> node[:id] == dg.parent_id end)
    dg_children = dg_children ++ Enum.filter(dd_all, fn(dd) -> node[:id] == dd.domain_group_id end)
    if dg_children do
      Enum.map(dg_children, fn(dg) -> build_node(dg, dg_all, dd_all) end)
    else
      []
    end
  end

  defp build_map(%DomainGroup{} = dg) do
    %{id: dg.id, name: dg.name, description: dg.description, parent_id: dg.parent_id, type: "DG", children: []}
  end

  defp build_map(%DataDomain{} = dd) do
    %{id: dd.id, name: dd.name, description: dd.description, parent_id: dd.domain_group_id, type: "DD", children: []}
  end

end
