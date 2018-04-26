defmodule TdBgWeb.AclEntryControllerTest do
  use TdBgWeb.ConnCase
  use PhoenixSwagger.SchemaTest, "priv/static/swagger.json"

  alias TdBgWeb.ApiServices.MockTdAuthService
  alias TdBg.Permissions.AclEntry
  alias TdBg.Permissions
  import TdBgWeb.Authentication, only: :functions

  @update_attrs %{principal_id: 43, principal_type: "user", resource_id: 43, resource_type: "domain"}
  @invalid_attrs %{principal_id: nil, principal_type: nil, resource_id: nil, resource_type: nil}

  setup_all do
    start_supervised MockTdAuthService
    :ok
  end

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    @tag :admin_authenticated
    test "lists all acl_entries", %{conn: conn} do
      conn = get conn, acl_entry_path(conn, :index)
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "create acl_entry" do
    @tag :admin_authenticated
    test "renders acl_entry when data is valid", %{conn: conn, swagger_schema: schema} do
      user = build(:user)
      domain = insert(:domain)
      role = Permissions.get_role_by_name("watch")
      acl_entry_attrs = build(:acl_entry_domain_user, principal_id: user.id, resource_id: domain.id, role_id: role.id)
      acl_entry_attrs = acl_entry_attrs |> Map.from_struct
      conn = post conn, acl_entry_path(conn, :create), acl_entry: acl_entry_attrs
      assert %{"id" => id} = json_response(conn, 201)["data"]
      validate_resp_schema(conn, schema, "AclEntryResponse")

      conn = recycle_and_put_headers(conn)
      conn = get conn, acl_entry_path(conn, :show, id)
      validate_resp_schema(conn, schema, "AclEntryResponse")
      assert json_response(conn, 200)["data"] == %{
        "id" => id,
        "principal_id" => user.id,
        "principal_type" => "user",
        "resource_id" => domain.id,
        "resource_type" => "domain",
        "role_id" => role.id
      }
    end

    @tag :admin_authenticated
    test "renders error for duplicated acl_entry", %{conn: conn, swagger_schema: schema} do
      user = build(:user)
      domain = insert(:domain)
      role = Permissions.get_role_by_name("watch")
      acl_entry_attrs = build(:acl_entry_domain_user, principal_id: user.id, resource_id: domain.id, role_id: role.id)
      acl_entry_attrs = acl_entry_attrs |> Map.from_struct
      conn = post conn, acl_entry_path(conn, :create), acl_entry: acl_entry_attrs
      assert %{"id" => _id} = json_response(conn, 201)["data"]
      validate_resp_schema(conn, schema, "AclEntryResponse")

      conn = recycle_and_put_headers(conn)
      conn = post conn, acl_entry_path(conn, :create), acl_entry: acl_entry_attrs
      assert json_response(conn, 422)["errors"] != %{}
    end

    @tag :admin_authenticated
    test "renders errors when data is invalid", %{conn: conn} do
      conn = post conn, acl_entry_path(conn, :create), acl_entry: @invalid_attrs
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "create or update acl_entry" do
    @tag :admin_authenticated
    test "renders acl_entry when creating a new acl", %{conn: conn, swagger_schema: schema} do
      user = build(:user)
      domain = insert(:domain)
      role = get_role_by_name(conn, Atom.to_string(:create))
      acl_entry_attrs = build(:acl_entry_domain_user, principal_id: user.id, resource_id: domain.id)
      acl_entry_attrs = acl_entry_attrs |> Map.from_struct
      acl_entry_attrs = Map.put(acl_entry_attrs, "role_name", role["name"])
      conn = post conn, acl_entry_path(conn, :create_or_update), acl_entry: acl_entry_attrs
      assert %{"id" => id} = json_response(conn, 201)["data"]
      validate_resp_schema(conn, schema, "AclEntryResponse")

      conn = recycle_and_put_headers(conn)
      conn = get conn, acl_entry_path(conn, :show, id)
      validate_resp_schema(conn, schema, "AclEntryResponse")
      assert json_response(conn, 200)["data"] == %{
               "id" => id,
               "principal_id" => user.id,
               "principal_type" => "user",
               "resource_id" => domain.id,
               "resource_type" => "domain",
               "role_id" => role["id"]
             }
    end

    @tag :admin_authenticated
    test "renders acl_entry when updating an existing acl", %{conn: conn, swagger_schema: schema} do
      user = build(:user)
      domain = insert(:domain)
      role = Permissions.get_role_by_name("watch")
      acl_entry_attrs = build(:acl_entry_domain_user, principal_id: user.id, resource_id: domain.id)
      acl_entry_attrs = acl_entry_attrs |> Map.from_struct
      acl_entry_attrs = Map.put(acl_entry_attrs, "role_name", role.name)
      conn = post conn, acl_entry_path(conn, :create_or_update), acl_entry: acl_entry_attrs
      assert %{"id" => _id} = json_response(conn, 201)["data"]
      validate_resp_schema(conn, schema, "AclEntryResponse")

      role = get_role_by_name(conn, Atom.to_string(:admin))

      conn = recycle_and_put_headers(conn)
      acl_entry_attrs = build(:acl_entry_domain_user, principal_id: user.id, resource_id: domain.id)
      acl_entry_attrs = acl_entry_attrs |> Map.from_struct
      acl_entry_attrs = Map.put(acl_entry_attrs, "role_name", role["name"])
      conn = post conn, acl_entry_path(conn, :create_or_update), acl_entry: acl_entry_attrs
      assert %{"id" => id} = json_response(conn, 200)["data"]
      validate_resp_schema(conn, schema, "AclEntryResponse")

      conn = recycle_and_put_headers(conn)
      conn = get conn, acl_entry_path(conn, :show, id)
      validate_resp_schema(conn, schema, "AclEntryResponse")
      assert json_response(conn, 200)["data"] == %{
               "id" => id,
               "principal_id" => user.id,
               "principal_type" => "user",
               "resource_id" => domain.id,
               "resource_type" => "domain",
               "role_id" => role["id"]
             }
    end
  end

  describe "update acl_entry" do
    setup [:create_acl_entry]

    @tag :admin_authenticated
    test "renders acl_entry when data is valid", %{conn: conn, swagger_schema: schema, acl_entry: %AclEntry{id: id, role_id: role_id} = acl_entry} do
      conn = put conn, acl_entry_path(conn, :update, acl_entry), acl_entry: @update_attrs
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = recycle_and_put_headers(conn)
      conn = get conn, acl_entry_path(conn, :show, id)
      validate_resp_schema(conn, schema, "AclEntryResponse")
      assert json_response(conn, 200)["data"] == %{
        "id" => id,
        "principal_id" => @update_attrs.principal_id,
        "principal_type" => @update_attrs.principal_type,
        "resource_id" => @update_attrs.resource_id,
        "resource_type" => @update_attrs.resource_type,
        "role_id" => role_id
       }
    end

    @tag :admin_authenticated
    test "renders errors when data is invalid", %{conn: conn, acl_entry: acl_entry} do
      conn = put conn, acl_entry_path(conn, :update, acl_entry), acl_entry: @invalid_attrs
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete acl_entry" do
    setup [:create_acl_entry]

    @tag :admin_authenticated
    test "deletes chosen acl_entry", %{conn: conn, acl_entry: acl_entry} do
      conn = delete conn, acl_entry_path(conn, :delete, acl_entry)
      assert response(conn, 204)
      conn = recycle_and_put_headers(conn)
      assert_error_sent 404, fn ->
        get conn, acl_entry_path(conn, :show, acl_entry)
      end
    end
  end

  defp create_acl_entry(_) do
    user = build(:user)
    domain = insert(:domain)
    role = Permissions.get_role_by_name("watch")
    acl_entry_attrs = insert(:acl_entry_domain_user, principal_id: user.id, resource_id: domain.id, role: role)
    {:ok, acl_entry: acl_entry_attrs}
  end

  defp get_role_by_name(conn, name) do
    conn = recycle_and_put_headers(conn)
    conn = get conn, role_path(conn, :index)
    roles = json_response(conn, 200)["data"]
    Enum.find(roles, fn(role) -> role["name"] == name end)
  end
end
