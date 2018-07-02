defmodule TdBgWeb.PermissionControllerTest do
  use TdBgWeb.ConnCase
  use PhoenixSwagger.SchemaTest, "priv/static/swagger.json"

  import TdBgWeb.Authentication, only: :functions

  alias TdBgWeb.ApiServices.MockTdAuditService
  alias TdBgWeb.ApiServices.MockTdAuthService
  # alias TdBg.Permissions
  alias TdBg.Permissions.Permission

  setup_all do
    start_supervised MockTdAuthService
    start_supervised MockTdAuditService
    :ok
  end

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    @tag :admin_authenticated
    test "lists all permissions", %{conn: conn, swagger_schema: schema} do
      conn = get conn, permission_path(conn, :index)
      validate_resp_schema(conn, schema, "PermissionsResponse")
      collection = json_response(conn, 200)["data"]
      stored_permissions = collection |> Enum.map(&Map.get(&1, "name")) |> Enum.sort
      current_permissions = Permission.permissions |> Map.values |> Enum.sort
      assert stored_permissions == current_permissions
    end
  end

  describe "show" do
    @tag :admin_authenticated
    test "show permission", %{conn: conn, swagger_schema: schema} do
      conn = get conn, permission_path(conn, :index)
      collection = json_response(conn, 200)["data"]
      permission = List.first(collection)
      permission_id = Map.get(permission, "id")

      conn = recycle_and_put_headers(conn)
      conn = get conn, permission_path(conn, :show, permission_id)
      validate_resp_schema(conn, schema, "PermissionResponse")
      assert permission == json_response(conn, 200)["data"]
    end
  end

  describe "role permissions" do

    @tag :admin_authenticated
    test "list role permissions", %{conn: conn, swagger_schema: schema} do
      conn = get conn, role_path(conn, :index)
      role = json_response(conn, 200)["data"] |> List.first
      role_id = role |> Map.get("id")

      conn = recycle_and_put_headers(conn)
      conn = get conn, role_permission_path(conn, :get_role_permissions, role_id)
      validate_resp_schema(conn, schema, "PermissionsResponse")
      collection = json_response(conn, 200)["data"]
      assert length(collection) != 0
    end

    @role_attrs %{name: "rolename"}

    @tag :admin_authenticated
    test "add permissions to role", %{conn: conn, swagger_schema: schema} do
      conn = get conn, permission_path(conn, :index)
      permissions = json_response(conn, 200)["data"]
      permissions = Enum.sort(permissions, &(Map.get(&1, "name") < Map.get(&2, "name")))

      conn = recycle_and_put_headers(conn)
      conn = post conn, role_path(conn, :create), role: @role_attrs
      validate_resp_schema(conn, schema, "RoleResponse")
      %{"id" => role_id} = json_response(conn, 201)["data"]

      conn = recycle_and_put_headers(conn)
      conn = post conn, role_permission_path(conn, :add_permissions_to_role, role_id), permissions: permissions
      validate_resp_schema(conn, schema, "PermissionsResponse")

      conn = recycle_and_put_headers(conn)
      conn = get conn, role_permission_path(conn, :get_role_permissions, role_id)
      validate_resp_schema(conn, schema, "PermissionsResponse")
      stored_permissions = json_response(conn, 200)["data"]
      stored_permissions = Enum.sort(stored_permissions, &(Map.get(&1, "name") < Map.get(&2, "name")))

      assert permissions == stored_permissions
    end

  end

end
