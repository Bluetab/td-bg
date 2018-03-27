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
    test "List one DG taxonomy tree", %{conn: conn, swagger_schema: schema} do

      build(:user)
      insert(:domain_group)

      conn = get conn, taxonomy_path(conn, :tree)
      validate_resp_schema(conn, schema, "TaxonomyTreeResponse")

      actual_tree = json_response(conn, 200)["data"]
      actual_tree = actual_tree |> Enum.map(fn(node) -> Map.take(node, ["children", "description", "name", "type"]) end)
      assert actual_tree == [%{"children" => [], "description" => "My domain group description", "name" => "My domain group", "type" => "DG"}]
    end

    @tag :admin_authenticated
    test "List DG DD taxonomy tree", %{conn: conn, swagger_schema: schema} do
      build(:user)
      insert(:data_domain)

      conn = get conn, taxonomy_path(conn, :tree)
      validate_resp_schema(conn, schema, "TaxonomyTreeResponse")

      actual_tree = json_response(conn, 200)["data"]
      actual_tree = remove_tree_keys(actual_tree)

      assert actual_tree == [%{"children" =>
                                [%{"children" => [], "description" => "My data domain description", "name" => "My data domain", "type" => "DD"}],
                              "description" => "My domain group description", "name" => "My domain group", "type" => "DG"}]
    end
  end

  describe "Taxonomy roles API call" do
    @tag :admin_authenticated
    test "Map empty taxonomy roles list", %{conn: conn} do
      user = build(:user)
      conn = get conn, taxonomy_path(conn, :roles, principal_id: user.id)
      assert json_response(conn, 200)["data"] == %{"data_domains" => %{}, "domain_groups" => %{}}
    end

    @tag :admin_authenticated
    test "List DGs custom role list", %{conn: conn, swagger_schema: schema} do
      user = build(:user)
      domain_group = insert(:domain_group)
      role = insert(:role_create)
      acl = insert(:acl_entry_domain_group_user, principal_id: user.id, resource_id: domain_group.id, role_id: role.id)

      conn = get conn, taxonomy_path(conn, :roles, principal_id: user.id)
      validate_resp_schema(conn, schema, "TaxonomyRolesResponse")

      actual_response = json_response(conn, 200)["data"]
      assert actual_response["domain_groups"][to_string(acl.resource_id)] == %{"inherited" => false, "role" => "create"}
    end

    @tag :admin_authenticated
    test "List DG DD custom role list", %{conn: conn, swagger_schema: schema} do
      user = build(:user)
      data_domain = insert(:data_domain)
      acl = insert(:acl_entry_data_domain_user, principal_id: user.id, resource_id: data_domain.id, role_id: insert(:role_publish).id)

      conn = get conn, taxonomy_path(conn, :roles, principal_id: user.id)
      validate_resp_schema(conn, schema, "TaxonomyRolesResponse")

      actual_response = json_response(conn, 200)["data"]
      assert actual_response["data_domains"][to_string(acl.resource_id)] == %{"inherited" => false, "role" => "publish"}
    end
  end
end
