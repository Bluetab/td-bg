defmodule TrueBGWeb.BusinessConceptVersionControllerTest do
  use TrueBGWeb.ConnCase
  use PhoenixSwagger.SchemaTest, "priv/static/swagger.json"

  import TrueBGWeb.Authentication, only: :functions

  alias Poison, as: JSON
  alias TrueBG.BusinessConcepts.BusinessConcept

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  @admin_user_name "app-admin"

  describe "index" do
    @tag authenticated_user: @admin_user_name
    test "lists all business_concept_versions", %{conn: conn} do
      conn = get conn, business_concept_version_path(conn, :index)
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "create business_concept_version" do
    setup [:create_content_schema]

    @tag authenticated_user: @admin_user_name
    test "renders business_concept_version when data is valid", %{conn: conn, swagger_schema: schema} do
      business_concept_version = insert(:business_concept_version, status: BusinessConcept.status.published)
      business_concept_id = business_concept_version.business_concept.id
      creation_attrs = %{
        content: %{},
        name: "Other name",
        description: "Other description"
      }

      conn = post conn, business_concept_business_concept_version_path(conn, :create, business_concept_id), business_concept: creation_attrs
      validate_resp_schema(conn, schema, "BusinessConceptVersionResponse")
      assert %{"id" => id} = json_response(conn, 200)["data"] # change response to created?

      conn = recycle_and_put_headers(conn)

      conn = get conn, business_concept_version_path(conn, :show, id)
      #validate_resp_schema(conn, schema, "BusinessConceptVersionResponse")
      business_concept_version = json_response(conn, 200)["data"]

      assert business_concept_version["version"] == 2

    end
  end

  def create_content_schema(_) do
    json_schema = %{"some type" => []} |> JSON.encode!
    path = Application.get_env(:trueBG, :bc_schema_location)
    File.write!(path, json_schema, [:write, :utf8])
  end

end
