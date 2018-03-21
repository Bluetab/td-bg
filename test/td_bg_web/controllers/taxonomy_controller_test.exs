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

  describe "tree" do
    @tag :admin_authenticated
    test "List empty taxonomy tree", %{conn: conn} do
      conn = get conn, taxonomy_path(conn, :tree)
      assert json_response(conn, 200)["data"] == []
    end

    @tag :admin_authenticated
    test "List one DG taxonomy tree", %{conn: conn} do

      build(:user)
      insert(:domain_group)
      #role = insert(:role)
      #acl_entry = insert(:acl_entry_domain_group_user, principal_id: user.id, resource_id: domain_group.id, role_id: role.id)

      conn = get conn, taxonomy_path(conn, :tree)

      actual_tree = json_response(conn, 200)["data"]
      actual_tree = actual_tree |> Enum.map(fn(node)-> Map.take(node, ["children", "description", "name", "type"]) end)

      assert actual_tree == [%{"children" => [], "description" => "My domain group description", "name" => "My domain group", "type" => "DG"}]
    end

    @tag :admin_authenticated
    test "List DG DD taxonomy tree", %{conn: conn} do
      build(:user)
      insert(:data_domain)

      conn = get conn, taxonomy_path(conn, :tree)

      actual_tree = json_response(conn, 200)["data"]
      actual_tree = remove_tree_keys(actual_tree) #actual_tree |> Enum.map(fn(node)-> Map.take(node, ["children", "description", "name", "type"]) end)

      assert actual_tree == [%{"children" =>
                                [%{"children" => [], "description" => "My data domain description", "name" => "My data domain", "type" => "DD"}],
                              "description" => "My domain group description", "name" => "My domain group", "type" => "DG"}]
    end
  end

end