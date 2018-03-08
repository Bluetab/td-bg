defmodule TdBgWeb.RoleControllerTest do
  use TdBgWeb.ConnCase
  use PhoenixSwagger.SchemaTest, "priv/static/swagger.json"

  import TdBgWeb.Authentication, only: :functions

  alias TdBg.Permissions
  alias TdBg.Permissions.Role

  @create_attrs %{name: "some name"}
  @update_attrs %{name: "some updated name"}
  @invalid_attrs %{name: nil}

  def fixture(:role) do
    {:ok, role} = Permissions.create_role(@create_attrs)
    role
  end

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    @tag :admin_authenticated
    test "lists all roles", %{conn: conn, swagger_schema: schema} do
      conn = get conn, role_path(conn, :index)
      validate_resp_schema(conn, schema, "RolesResponse")
      assert length(json_response(conn, 200)["data"]) == length(Role.get_roles())
    end
  end

  describe "create role" do
    @tag :admin_authenticated
    test "renders role when data is valid", %{conn: conn, swagger_schema: schema} do
      conn = post conn, role_path(conn, :create), role: @create_attrs
      validate_resp_schema(conn, schema, "RoleResponse")
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = recycle_and_put_headers(conn)
      conn = get conn, role_path(conn, :show, id)
      validate_resp_schema(conn, schema, "RoleResponse")
      assert json_response(conn, 200)["data"] == %{
        "id" => id,
        "name" => "some name"}
    end

    @tag :admin_authenticated
    test "renders errors when data is invalid", %{conn: conn} do
      conn = post conn, role_path(conn, :create), role: @invalid_attrs
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update role" do
    setup [:create_role]

    @tag :admin_authenticated
    test "renders role when data is valid", %{conn: conn, swagger_schema: schema, role: %Role{id: id} = role} do
      conn = put conn, role_path(conn, :update, role), role: @update_attrs
      validate_resp_schema(conn, schema, "RoleResponse")
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = recycle_and_put_headers(conn)
      conn = get conn, role_path(conn, :show, id)
      validate_resp_schema(conn, schema, "RoleResponse")
      assert json_response(conn, 200)["data"] == %{
        "id" => id,
        "name" => "some updated name"}
    end

    @tag :admin_authenticated
    test "renders errors when data is invalid", %{conn: conn, role: role} do
      conn = put conn, role_path(conn, :update, role), role: @invalid_attrs
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete role" do
    setup [:create_role]

    @tag :admin_authenticated
    test "deletes chosen role", %{conn: conn, role: role} do
      conn = delete conn, role_path(conn, :delete, role)
      assert response(conn, 204)
      conn = recycle_and_put_headers(conn)
      assert_error_sent 404, fn ->
        get conn, role_path(conn, :show, role)
      end
    end
  end

  defp create_role(_) do
    role = fixture(:role)
    {:ok, role: role}
  end
end
