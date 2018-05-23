defmodule TdBgWeb.TaxonomyControllerTest do
  use TdBgWeb.ConnCase
  use PhoenixSwagger.SchemaTest, "priv/static/swagger.json"

  import TdBgWeb.Authentication, only: :functions
  alias TdBg.Permissions
  alias TdBgWeb.ApiServices.MockTdAuthService

  setup_all do
    start_supervised MockTdAuthService
    :ok
  end

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "Taxonomy roles API call" do
    @tag :admin_authenticated
    test "Map empty taxonomy roles list", %{conn: conn} do
      user = build(:user)
      conn = get conn, taxonomy_path(conn, :roles, principal_id: user.id)
      assert json_response(conn, 200)["data"] == %{"domains" => %{}}
    end

    @tag :admin_authenticated
    test "List domains custom role list", %{conn: conn, swagger_schema: schema} do
      user = build(:user)
      domain = insert(:domain)
      role = Permissions.get_role_by_name("create")
      acl = insert(:acl_entry_domain_user, principal_id: user.id, resource_id: domain.id, role_id: role.id)

      conn = get conn, taxonomy_path(conn, :roles, principal_id: user.id)
      validate_resp_schema(conn, schema, "TaxonomyRolesResponse")

      actual_response = json_response(conn, 200)["data"]
      role_response = actual_response["domains"][to_string(acl.resource_id)]
      assert role_response["inherited"]  == false
      assert role_response["role"] == "create"
      assert role_response["acl_entry_id"] != nil
    end

    @tag :admin_authenticated
    test "List children domain custom role list", %{conn: conn, swagger_schema: schema} do
      user = build(:user)
      user = create_user(user.user_name)
      child_domain = insert(:child_domain)
      role = Permissions.get_role_by_name("publish")
      acl = insert(:acl_entry_domain_user, principal_id: user.id, resource_id: child_domain.id, role_id: role.id)

      conn = get conn, taxonomy_path(conn, :roles, principal_id: user.id)
      validate_resp_schema(conn, schema, "TaxonomyRolesResponse")

      actual_response = json_response(conn, 200)["data"]
      role_response = actual_response["domains"][to_string(acl.resource_id)]
      assert role_response["inherited"]  == false
      assert role_response["role"] == "publish"
      assert role_response["acl_entry_id"] != nil
    end
  end
end
