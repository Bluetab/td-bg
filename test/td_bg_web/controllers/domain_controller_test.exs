defmodule TdBgWeb.DomainControllerTest do
  use TdBgWeb.ConnCase
  use PhoenixSwagger.SchemaTest, "priv/static/swagger.json"

  import TdBgWeb.Authentication, only: :functions

  alias TdBg.Permissions.Role
  alias TdBg.Permissions.MockPermissionResolver
  alias TdBg.Taxonomies
  alias TdBg.Taxonomies.Domain
  alias TdBgWeb.ApiServices.MockTdAuditService
  alias TdBgWeb.ApiServices.MockTdAuthService

  @create_attrs %{description: "some description", name: "some name"}
  @update_attrs %{description: "some updated description", name: "some updated name"}
  @invalid_attrs %{description: nil, name: nil}

  @user_name "user"

  def fixture(:domain) do
    {:ok, domain} = Taxonomies.create_domain(@create_attrs)
    domain
  end

  setup_all do
    start_supervised MockTdAuthService
    start_supervised MockTdAuditService
    start_supervised MockPermissionResolver
    :ok
  end

  setup %{conn: conn, jwt: _jwt} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    @tag :admin_authenticated
    test "lists all domains", %{conn: conn} do
      conn = get conn, domain_path(conn, :index)
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "index with actions" do
    @tag authenticated_user: @user_name
    test "list all domains user can view",
      %{conn: conn, swagger_schema: schema} do
        user = create_user(@user_name)
        domain = insert(:domain)
        role = Role.get_role_by_name("watch")
        MockPermissionResolver.create_acl_entry(%{
          principal_id: user.id,
          principal_type: "user",
          resource_id: domain.id,
          resource_type: "domain",
          role_id: role.id,
          role_name: role.name
        })
        parameters = %{actions: "show"}
        conn = get conn, domain_path(conn, :index, parameters)
        response_data = json_response(conn, 200)["data"]
        assert length(response_data) == 1
        validate_resp_schema(conn, schema, "DomainsResponse")
    end

    @tag authenticated_user: @user_name
    test "user cant view any domain",
      %{conn: conn, swagger_schema: schema} do
        create_user(@user_name)
        insert(:domain)
        parameters = %{actions: "show"}
        conn = get conn, domain_path(conn, :index, parameters)
        response_data = json_response(conn, 200)["data"]
        assert Enum.empty?(response_data)
        validate_resp_schema(conn, schema, "DomainsResponse")
    end

  end

  describe "create domain" do
    @tag :admin_authenticated
    test "renders domain when data is valid", %{conn: conn, swagger_schema: schema} do
      conn = post conn, domain_path(conn, :create), domain: @create_attrs
      assert %{"id" => id} = json_response(conn, 201)["data"]
      validate_resp_schema(conn, schema, "DomainResponse")

      conn = recycle_and_put_headers(conn)
      conn = get conn, domain_path(conn, :show, id)
      json_response_data = json_response(conn, 200)["data"]
      validate_resp_schema(conn, schema, "DomainResponse")
      assert json_response_data["id"] == id
      assert json_response_data["description"] == "some description"
      assert json_response_data["name"] == "some name"
      assert json_response_data["parent_id"] == nil
    end

    @tag :admin_authenticated
    test "renders errors when data is invalid", %{conn: conn} do
      conn = post conn, domain_path(conn, :create), domain: @invalid_attrs
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update domain" do
    setup [:create_domain]

    @tag :admin_authenticated
    test "renders domain when data is valid", %{conn: conn, swagger_schema: schema, domain: %Domain{id: id} = domain} do
      conn = put conn, domain_path(conn, :update, domain), domain: @update_attrs
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = recycle_and_put_headers(conn)
      conn = get conn, domain_path(conn, :show, id)
      validate_resp_schema(conn, schema, "DomainResponse")
      assert json_response(conn, 200)["data"]["id"] == id
      assert json_response(conn, 200)["data"]["description"] == "some updated description"
      assert json_response(conn, 200)["data"]["name"] == "some updated name"
      assert json_response(conn, 200)["data"]["parent_id"] == nil
    end

    @tag :admin_authenticated
    test "renders errors when data is invalid", %{conn: conn, domain: domain} do
      conn = put conn, domain_path(conn, :update, domain), domain: @invalid_attrs
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete domain" do
    setup [:create_domain]

    @tag :admin_authenticated
    test "deletes chosen domain", %{conn: conn, domain: domain} do
      conn = delete conn, domain_path(conn, :delete, domain)

      assert response(conn, 204)
      conn = recycle_and_put_headers(conn)
      assert_error_sent 404, fn ->
        get conn, domain_path(conn, :show, domain)
      end
    end
  end

  describe "create acl_entry from domain route" do
    @tag :admin_authenticated
    test "renders acl_entry when data is valid", %{conn: conn, swagger_schema: schema} do
      user = build(:user)
      domain = insert(:domain)
      role = Role.get_role_by_name("watch")
      acl_entry_attrs = %{
        principal_id: user.id,
        principal_type: "user",
        role_id: role.id
      }
      conn = post conn, domain_domain_path(conn, :create_acl_entry, domain.id), acl_entry: acl_entry_attrs
      assert %{"id" => id} = json_response(conn, 201)["data"]
      validate_resp_schema(conn, schema, "DomainAclEntryResponse")

      conn = recycle_and_put_headers(conn)
      conn = get conn, acl_entry_path(conn, :show, id)
      validate_resp_schema(conn, schema, "DomainAclEntryResponse")
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
    test "renders error for duplicated acl_entry from domain route", %{conn: conn, swagger_schema: schema} do
      user = build(:user)
      domain = insert(:domain)
      role = Role.get_role_by_name("watch")
      acl_entry_attrs = %{
        principal_id: user.id,
        principal_type: "user",
        role_id: role.id
      }
      conn = post conn, domain_domain_path(conn, :create_acl_entry, domain.id), acl_entry: acl_entry_attrs
      assert %{"id" => _id} = json_response(conn, 201)["data"]
      validate_resp_schema(conn, schema, "DomainAclEntryResponse")

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

  defp create_domain(_) do
    domain = fixture(:domain)
    {:ok, domain: domain}
  end
end
