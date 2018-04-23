defmodule TdBgWeb.TaxonomyControllerTest do
  use TdBgWeb.ConnCase
  use PhoenixSwagger.SchemaTest, "priv/static/swagger.json"

  alias TdBgWeb.ApiServices.MockTdAuthService

  import TdBgWeb.Taxonomy

  setup_all do
    start_supervised MockTdAuthService
    :ok
  end

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "Taxonomy tree API call" do
    @tag :admin_authenticated
    test "List empty taxonomy tree", %{conn: conn} do
      conn = get conn, taxonomy_path(conn, :tree)
      assert json_response(conn, 200)["data"] == []
    end

    @tag :admin_authenticated
    test "List one Domain taxonomy tree", %{conn: conn, swagger_schema: schema} do

      build(:user)
      insert(:domain)

      conn = get conn, taxonomy_path(conn, :tree)
      validate_resp_schema(conn, schema, "TaxonomyTreeResponse")

      actual_tree = json_response(conn, 200)["data"]
      actual_tree = actual_tree |> Enum.map(fn(node) -> Map.take(node, ["children", "description", "name"]) end)
      assert actual_tree == [%{"children" => [], "description" => "My domain description", "name" => "My domain"}]
    end

    @tag :admin_authenticated
    test "List Domains taxonomy tree", %{conn: conn, swagger_schema: schema} do
      build(:user)
      insert(:child_domain)

      conn = get conn, taxonomy_path(conn, :tree)
      validate_resp_schema(conn, schema, "TaxonomyTreeResponse")

      actual_tree = json_response(conn, 200)["data"]
      actual_tree = remove_tree_keys(actual_tree)

      assert actual_tree == [%{"children" =>
                                [%{"children" => [], "description" => "My child domain description", "name" => "My child domain"}],
                              "description" => "My domain description", "name" => "My domain"}]
    end
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
      role = insert(:role_create)
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
      child_domain = insert(:child_domain)
      acl = insert(:acl_entry_domain_user, principal_id: user.id, resource_id: child_domain.id, role_id: insert(:role_publish).id)

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
