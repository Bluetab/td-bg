defmodule TrueBGWeb.AclEntryControllerTest do
  use TrueBGWeb.ConnCase

  alias TrueBG.Permissions
  alias TrueBG.Permissions.AclEntry
  import TrueBGWeb.Authentication, only: :functions

  @create_attrs %{principal_id: 42, principal_type: "some principal_type", resource_id: 42, resource_type: "some resource_type"}
  @update_attrs %{principal_id: 43, principal_type: "user", resource_id: 43, resource_type: "some updated resource_type"}
  @invalid_attrs %{principal_id: nil, principal_type: nil, resource_id: nil, resource_type: nil}

  def fixture(:acl_entry) do
    {:ok, acl_entry} = Permissions.create_acl_entry(@create_attrs)
    acl_entry
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
    test "renders acl_entry when data is valid", %{conn: conn} do
      user = insert(:user)
      domain_group = insert(:domain_group)
      role = insert(:role)
      acl_entry_attrs = insert(:acl_entry_domain_group_user, principal_id: user.id, resource_id: domain_group.id, role_id: role.id)
      acl_entry_attrs = acl_entry_attrs |> Map.from_struct
      conn = post conn, acl_entry_path(conn, :create), acl_entry: acl_entry_attrs
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = recycle_and_put_headers(conn)
      conn = get conn, acl_entry_path(conn, :show, id)
      assert json_response(conn, 200)["data"] == %{
        "id" => id,
        "principal_id" => user.id,
        "principal_type" => "user",
        "resource_id" => domain_group.id,
        "resource_type" => "domain_group"}
    end

    @tag :admin_authenticated
    test "renders errors when data is invalid", %{conn: conn} do
      conn = post conn, acl_entry_path(conn, :create), acl_entry: @invalid_attrs
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update acl_entry" do
    setup [:create_acl_entry]

    @tag :admin_authenticated
    test "renders acl_entry when data is valid", %{conn: conn, acl_entry: %AclEntry{id: id} = acl_entry} do
      conn = put conn, acl_entry_path(conn, :update, acl_entry), acl_entry: @update_attrs
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = recycle_and_put_headers(conn)
      conn = get conn, acl_entry_path(conn, :show, id)
      assert json_response(conn, 200)["data"] == %{
        "id" => id,
        "principal_id" => 43,
        "principal_type" => "user",
        "resource_id" => 43,
        "resource_type" => "some updated resource_type"}
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
    user = insert(:user)
    domain_group = insert(:domain_group)
    role = insert(:role)
    acl_entry_attrs = insert(:acl_entry_domain_group_user, principal_id: user.id, resource_id: domain_group.id, role: role)
    {:ok, acl_entry: acl_entry_attrs}
  end
end
