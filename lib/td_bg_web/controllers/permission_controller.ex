defmodule TdBgWeb.PermissionController do
  use TdBgWeb, :controller
  use PhoenixSwagger

  import Canada, only: [can?: 2]

  alias TdBgWeb.ErrorView
  alias TdBg.Permissions
  alias TdBgWeb.SwaggerDefinitions
  alias Guardian.Plug, as: GuardianPlug

  action_fallback TdBgWeb.FallbackController

  def swagger_definitions do
    SwaggerDefinitions.permission_swagger_definitions()
  end

  swagger_path :index do
    get "/permissions"
    description "List Permissions"
    response 200, "OK", Schema.ref(:PermissionsResponse)
  end

  def index(conn, _params) do
    current_user = get_current_user(conn)
    case can?(current_user, index(Permission)) do
      true ->
        permissions = Permissions.list_permissions()
        render(conn, "index.json", permissions: permissions)
      false ->
        conn
        |> put_status(:forbidden)
        |> render(ErrorView, :"403.json")
    end
  end

  swagger_path :show do
    get "/permissions/{id}"
    description "Show Permission"
    produces "application/json"
    parameters do
      id :path, :integer, "Permission ID", required: true
    end
    response 200, "OK", Schema.ref(:PermissionResponse)
    response 400, "Client Error"
  end

  def show(conn, %{"id" => id}) do
    current_user = get_current_user(conn)
    permission = Permissions.get_permission!(id)
    case can?(current_user, show(permission)) do
      true ->
        render(conn, "show.json", permission: permission)
      false ->
        conn
        |> put_status(:forbidden)
        |> render(ErrorView, :"403.json")
    end
  end

  swagger_path :get_role_permissions do
    get "/roles/{role_id}/permissions"
    description "List Role Permissions"
    parameters do
      role_id :path, :integer, "Role ID", required: true
    end
    response 200, "OK", Schema.ref(:PermissionsResponse)
  end

  def get_role_permissions(conn, %{"role_id" => role_id}) do
    current_user = get_current_user(conn)
    role = Permissions.get_role!(role_id)
    case can?(current_user, get_role(role)) do
      true ->
        permissions = Permissions.get_role_permissions(role)
        render(conn, "index.json", permissions: permissions)
      false ->
        conn
        |> put_status(:forbidden)
        |> render(ErrorView, :"403.json")
    end
  end

  swagger_path :add_permissions_to_role do
    post "/roles/{role_id}/permissions"
    description "Add Permissions to Role"
    parameters do
      role_id :path, :integer, "Role ID", required: true
      permissions :body, Schema.ref(:AddPermissionsToRole), "Add Permissions to Role attrs"
    end
    response 200, "OK", Schema.ref(:PermissionsResponse)
  end

  def add_permissions_to_role(conn, %{"role_id" => role_id, "permissions" => perms}) do
    current_user = get_current_user(conn)
    role = Permissions.get_role!(role_id)
    case can?(current_user, add_permissions_to_role(role)) do
      true ->
        permissions = Enum.map(perms, &Permissions.get_permission!(Map.get(&1, "id")))
        Permissions.add_permissions_to_role(role, permissions)
        render(conn, "index.json", permissions: permissions)
      false ->
        conn
        |> put_status(:forbidden)
        |> render(ErrorView, :"403.json")
    end
  end

  defp get_current_user(conn) do
    GuardianPlug.current_resource(conn)
  end

end
