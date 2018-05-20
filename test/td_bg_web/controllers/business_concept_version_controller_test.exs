defmodule TdBgWeb.BusinessConceptVersionControllerTest do
  use TdBgWeb.ConnCase
  use PhoenixSwagger.SchemaTest, "priv/static/swagger.json"

  import TdBgWeb.Authentication, only: :functions

  alias TdBgWeb.ApiServices.MockTdAuthService
  alias TdBg.BusinessConcepts.BusinessConcept
  alias TdBg.Permissions

  setup_all do
    start_supervised MockTdAuthService
    :ok
  end

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  @admin_user_name "app-admin"

  describe "show" do
    @tag authenticated_user: @admin_user_name
    test "shows the specified business_concept_version including it's name, description, domain and content", %{conn: conn} do
      business_concept_version = insert(:business_concept_version, content: %{"foo" => "bar"}, name: "Concept Name", description: "The awesome concept")
      conn = get conn, business_concept_version_path(conn, :show, business_concept_version.id)
      data = json_response(conn, 200)["data"]
      assert data["name"] == business_concept_version.name
      assert data["description"] == business_concept_version.description
      assert data["business_concept_id"] == business_concept_version.business_concept.id
      assert data["content"] == business_concept_version.content
      assert data["domain"]["id"] == business_concept_version.business_concept.domain.id
      assert data["domain"]["name"] == business_concept_version.business_concept.domain.name
    end
  end

  describe "index" do
    @tag authenticated_user: @admin_user_name
    test "lists all business_concept_versions", %{conn: conn} do
      conn = get conn, business_concept_version_path(conn, :index)
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "versions" do
    @tag authenticated_user: @admin_user_name
    test "lists business_concept_versions", %{conn: conn} do
      business_concept_version = insert(:business_concept_version)
      business_concept_id = business_concept_version.business_concept.id
      conn = get conn, business_concept_business_concept_version_path(conn, :versions, business_concept_id)
      [data|_] = json_response(conn, 200)["data"]
      assert data["name"] == business_concept_version.name
    end
  end

  describe "query_business_concept_taxonomy" do
    @tag authenticated_user: @admin_user_name
    test "list the taxonomies of a business concept", %{conn: conn} do
      published = BusinessConcept.status.published
      user = build(:user)
      user = create_user(user.user_name, is_admin: true)
      domain = insert(:domain)
      role = Permissions.get_role_by_name("watch")
      insert(:acl_entry_domain_user, principal_id: user.id, resource_id: domain.id, role: role)
      business_concept_version = create_version(domain, "one", published)
      business_concept_version_id = business_concept_version.id
      conn = recycle_and_put_headers(conn)
      conn = get conn, business_concept_version_business_concept_version_path(conn, :taxonomy_roles, business_concept_version_id)
      collection = json_response(conn, 200)["data"]
      assert Enum.member?(Enum.map(collection, &(&1["domain_name"])), domain.name)
      assert Enum.member?(Enum.map(collection, &(&1["domain_id"])), domain.id)
      roles = Enum.find(collection, &(&1["domain_name"] == domain.name))["roles"]
      assert Enum.member?(Enum.map(roles, &(&1["principal"]["id"])), user.id)
    end
  end

  defp create_version(domain, name, status) do
    business_concept = insert(:business_concept, domain: domain)
    insert(:business_concept_version, business_concept: business_concept, name: name, status: status)
  end

end
