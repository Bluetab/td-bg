defmodule TdBgWeb.DataDomainControllerTest do
  use TdBgWeb.ConnCase
  use PhoenixSwagger.SchemaTest, "priv/static/swagger.json"

  import TdBgWeb.Authentication, only: :functions

  alias TdBgWeb.ApiServices.MockTdAuthService
  alias TdBg.Taxonomies
  alias TdBg.Taxonomies.DataDomain

  @create_attrs %{description: "some description", name: "some name"}
  @update_attrs %{description: "some updated description", name: "some updated name"}
  @invalid_attrs %{description: nil, name: nil}

  def fixture(:data_domain) do
    {:ok, data_domain} = Taxonomies.create_data_domain(@create_attrs)
    data_domain
  end

  setup_all do
    start_supervised MockTdAuthService
    :ok
  end

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    @tag :admin_authenticated
    test "lists all data_domains", %{conn: conn} do
      conn = get conn, data_domain_path(conn, :index)
      assert json_response(conn, 200)["data"]["collection"] == []
    end
  end

  describe "create data_domain" do
    @tag :admin_authenticated
    test "renders data_domain when data is valid", %{conn: conn, swagger_schema: schema} do
      domain_group = insert(:domain_group)

      creation_attrs = %{
        description: "some description",
        name: "some name",
        domain_group_id: domain_group.id
      }

      conn = post conn, data_domain_path(conn, :create), data_domain: creation_attrs
      validate_resp_schema(conn, schema, "DataDomainResponse")
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = recycle_and_put_headers(conn)
      conn = get conn, data_domain_path(conn, :show, id)

      validate_resp_schema(conn, schema, "DataDomainResponse")
      assert json_response(conn, 200)["data"]["id"] == id
      assert json_response(conn, 200)["data"]["description"] == "some description"
      assert json_response(conn, 200)["data"]["name"] == "some name"
      assert json_response(conn, 200)["data"]["domain_group_id"] == domain_group.id
    end

    @tag :admin_authenticated
    test "renders errors when data is invalid", %{conn: conn} do
      domain_group = insert(:domain_group)

      creation_attrs = %{
        description: nil,
        name: nil,
        domain_group_id: domain_group.id
      }

      conn = post conn, data_domain_path(conn, :create), data_domain: creation_attrs
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update data_domain" do
    setup [:create_data_domain]

    @tag :admin_authenticated
    test "renders data_domain when data is valid", %{conn: conn, swagger_schema: schema, data_domain: %DataDomain{id: id} = data_domain} do
      conn = put conn, data_domain_path(conn, :update, data_domain), data_domain: @update_attrs
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = recycle_and_put_headers(conn)
      conn = get conn, data_domain_path(conn, :show, id)
      validate_resp_schema(conn, schema, "DataDomainResponse")
      assert json_response(conn, 200)["data"]["id"] == id
      assert json_response(conn, 200)["data"]["description"] == "some updated description"
      assert json_response(conn, 200)["data"]["name"] == "some updated name"
      assert json_response(conn, 200)["data"]["domain_group_id"] == nil
    end

    @tag :admin_authenticated
    test "renders errors when data is invalid", %{conn: conn, jwt: _jwt, data_domain: data_domain} do
      conn = put conn, data_domain_path(conn, :update, data_domain), data_domain: @invalid_attrs
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete data_domain" do
    setup [:create_data_domain]

    @tag :admin_authenticated
    test "deletes chosen data_domain", %{conn: conn, data_domain: data_domain} do
      conn = delete conn, data_domain_path(conn, :delete, data_domain)
      assert response(conn, 204)
      conn = recycle_and_put_headers(conn)
      assert_error_sent 404, fn ->
        get conn, data_domain_path(conn, :show, data_domain)
      end
    end
  end

  defp create_data_domain(_) do
    data_domain = fixture(:data_domain)
    {:ok, data_domain: data_domain}
  end
end
