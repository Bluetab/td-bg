defmodule TdBgWeb.DomainGroupControllerTest do
  use TdBgWeb.ConnCase
  use PhoenixSwagger.SchemaTest, "priv/static/swagger.json"

  import TdBgWeb.Authentication, only: :functions

  alias TdBgWeb.ApiServices.MockTdAuthService
  alias TdBg.Taxonomies
  alias TdBg.Taxonomies.DomainGroup

  @create_attrs %{description: "some description", name: "some name"}
  @update_attrs %{description: "some updated description", name: "some updated name"}
  @invalid_attrs %{description: nil, name: nil}

  def fixture(:domain_group) do
    {:ok, domain_group} = Taxonomies.create_domain_group(@create_attrs)
    domain_group
  end

  setup_all do
    start_supervised MockTdAuthService
    :ok
  end

  setup %{conn: conn, jwt: _jwt} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    @tag :admin_authenticated
    test "lists all domain_groups", %{conn: conn} do
      conn = get conn, domain_group_path(conn, :index)
      assert json_response(conn, 200)["data"]["collection"] == []
    end
  end

  describe "create domain_group" do
    @tag :admin_authenticated
    test "renders domain_group when data is valid", %{conn: conn, swagger_schema: schema} do
      conn = post conn, domain_group_path(conn, :create), domain_group: @create_attrs
      assert %{"id" => id} = json_response(conn, 201)["data"]
      validate_resp_schema(conn, schema, "DomainGroupResponse")

      conn = recycle_and_put_headers(conn)
      conn = get conn, domain_group_path(conn, :show, id)
      json_response_data = json_response(conn, 200)["data"]
      validate_resp_schema(conn, schema, "DomainGroupResponse")
      assert json_response_data["id"] == id
      assert json_response_data["description"] == "some description"
      assert json_response_data["name"] == "some name"
      assert json_response_data["parent_id"] == nil
    end

    @tag :admin_authenticated
    test "renders errors when data is invalid", %{conn: conn} do
      conn = post conn, domain_group_path(conn, :create), domain_group: @invalid_attrs
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update domain_group" do
    setup [:create_domain_group]

    @tag :admin_authenticated
    test "renders domain_group when data is valid", %{conn: conn, swagger_schema: schema, domain_group: %DomainGroup{id: id} = domain_group} do
      conn = put conn, domain_group_path(conn, :update, domain_group), domain_group: @update_attrs
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = recycle_and_put_headers(conn)
      conn = get conn, domain_group_path(conn, :show, id)
      validate_resp_schema(conn, schema, "DomainGroupResponse")
      assert json_response(conn, 200)["data"]["id"] == id
      assert json_response(conn, 200)["data"]["description"] == "some updated description"
      assert json_response(conn, 200)["data"]["name"] == "some updated name"
      assert json_response(conn, 200)["data"]["parent_id"] == nil
    end

    @tag :admin_authenticated
    test "renders errors when data is invalid", %{conn: conn, domain_group: domain_group} do
      conn = put conn, domain_group_path(conn, :update, domain_group), domain_group: @invalid_attrs
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "index root" do
    setup [:create_domain_group]

    @tag :admin_authenticated
    test "lists root domain groups", %{conn: conn, swagger_schema: schema, domain_group: domain_group} do
      conn = get conn, domain_group_path(conn, :index_root)
      validate_resp_schema(conn, schema, "DomainGroupsResponse")
      assert List.first(json_response(conn, 200)["data"]["collection"])["id"] == domain_group.id
      assert List.first(json_response(conn, 200)["data"]["collection"])["description"] == domain_group.description
      assert List.first(json_response(conn, 200)["data"]["collection"])["name"] == domain_group.name
      assert List.first(json_response(conn, 200)["data"]["collection"])["parent_id"] == domain_group.parent_id
    end
  end

  describe "index_children" do
    setup [:create_child_domain_group]

    @tag :admin_authenticated
    test "index domain group children", %{conn: conn, swagger_schema: schema, child_domain_group: {:ok, child_domain_group}} do
      conn = get conn, domain_group_domain_group_path(conn,  :index_children, child_domain_group.parent_id)
      validate_resp_schema(conn, schema, "DomainGroupsResponse")
      assert List.first(json_response(conn, 200)["data"]["collection"])["id"] == child_domain_group.id
      assert List.first(json_response(conn, 200)["data"]["collection"])["description"] == child_domain_group.description
      assert List.first(json_response(conn, 200)["data"]["collection"])["name"] == child_domain_group.name
      assert List.first(json_response(conn, 200)["data"]["collection"])["parent_id"] == child_domain_group.parent_id
    end
  end

  describe "delete domain_group" do
    setup [:create_domain_group]

    @tag :admin_authenticated
    test "deletes chosen domain_group", %{conn: conn, domain_group: domain_group} do
      conn = delete conn, domain_group_path(conn, :delete, domain_group)

      assert response(conn, 204)
      conn = recycle_and_put_headers(conn)
      assert_error_sent 404, fn ->
        get conn, domain_group_path(conn, :show, domain_group)
      end
    end
  end

  defp create_domain_group(_) do
    domain_group = fixture(:domain_group)
    {:ok, domain_group: domain_group}
  end

  defp create_child_domain_group(_) do
    {:ok, domain_group} =  Taxonomies.create_domain_group(@create_attrs)
    child_domain_group = Taxonomies.create_domain_group(%{parent_id: domain_group.id, description: "some child description", name: "some child name"})
    {:ok, child_domain_group: child_domain_group}
  end
end
