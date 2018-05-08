defmodule TdBgWeb.BusinessConceptVersionControllerTest do
  use TdBgWeb.ConnCase
  use PhoenixSwagger.SchemaTest, "priv/static/swagger.json"

  import TdBgWeb.Authentication, only: :functions

  alias TdBgWeb.ApiServices.MockTdAuthService
  alias Poison, as: JSON
  alias TdBg.BusinessConcepts.BusinessConcept

  setup_all do
    start_supervised MockTdAuthService
    :ok
  end

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  @admin_user_name "app-admin"

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

  describe "create business_concept_version" do
    setup [:create_template]

    @tag authenticated_user: @admin_user_name
    test "renders business_concept_version when data is valid", %{conn: conn, swagger_schema: schema} do
      business_concept_version = insert(:business_concept_version, status: BusinessConcept.status.published)
      business_concept_id = business_concept_version.business_concept.id
      creation_attrs = %{
        content: %{},
        name: "Other name",
        description: "Other description"
      }

      conn = post conn, business_concept_business_concept_version_path(conn, :create, business_concept_id), business_concept_version: creation_attrs
      validate_resp_schema(conn, schema, "BusinessConceptVersionResponse")
      assert %{"id" => id} = json_response(conn, 201)["data"] # change response to created?

      conn = recycle_and_put_headers(conn)

      conn = get conn, business_concept_version_path(conn, :show, id)
      #validate_resp_schema(conn, schema, "BusinessConceptVersionResponse")
      business_concept_version = json_response(conn, 200)["data"]

      assert business_concept_version["current"] == true
      assert business_concept_version["version"] == 2

    end
  end

  def create_template(_) do
    headers = get_header(get_user_token("app-admin"))
    attrs = %{}
      |> Map.put("name", "some type")
      |> Map.put("content", [])
    body = %{template: attrs} |> JSON.encode!
    HTTPoison.post!(template_url(@endpoint, :create), body, headers, [])
    :ok
  end

end
