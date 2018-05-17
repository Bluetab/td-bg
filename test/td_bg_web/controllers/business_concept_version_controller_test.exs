defmodule TdBgWeb.BusinessConceptVersionControllerTest do
  use TdBgWeb.ConnCase
  use PhoenixSwagger.SchemaTest, "priv/static/swagger.json"

  alias TdBgWeb.ApiServices.MockTdAuthService

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
      assert json_response(conn, 200)["data"]["collection"] == []
    end
  end

  describe "versions" do
    @tag authenticated_user: @admin_user_name
    test "lists business_concept_versions", %{conn: conn} do
      business_concept_version = insert(:business_concept_version)
      business_concept_id = business_concept_version.business_concept.id
      conn = get conn, business_concept_business_concept_version_path(conn, :versions, business_concept_id)
      [data] = json_response(conn, 200)["data"]["collection"]
      assert data["name"] == business_concept_version.name
    end
  end

end
