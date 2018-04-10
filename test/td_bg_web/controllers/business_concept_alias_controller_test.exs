defmodule TdBgWeb.BusinessConceptAliasControllerTest do
  use TdBgWeb.ConnCase
  use PhoenixSwagger.SchemaTest, "priv/static/swagger.json"

  alias TdBgWeb.ApiServices.MockTdAuthService

  import TdBgWeb.Authentication, only: :functions

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
    test "lists all business_concept_aliases", %{conn: conn} do
      conn = get conn, business_concept_business_concept_alias_path(conn, :index, 123)
      assert json_response(conn, 200)["data"]["collection"] == []
    end
  end

  describe "create business_concept_alias" do
    @tag authenticated_user: @admin_user_name
    test "renders business_concept_alias when data is valid", %{conn: conn, swagger_schema: schema} do
      business_concept_version = insert(:business_concept_version)
      business_concept_id = business_concept_version.business_concept.id

      creation_attrs = %{
        name: "some name"
      }

      conn = post conn, business_concept_business_concept_alias_path(conn, :create, business_concept_id), business_concept_alias: creation_attrs
      validate_resp_schema(conn, schema, "BusinessConceptAliasResponse")
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = recycle_and_put_headers(conn)

      conn = get conn, business_concept_alias_path(conn, :show, id)
      validate_resp_schema(conn, schema, "BusinessConceptAliasResponse")
      assert json_response(conn, 200)["data"] == %{
        "id" => id,
        "business_concept_id" => business_concept_id,
        "name" => "some name"}
    end

    @tag authenticated_user: @admin_user_name
    test "renders errors when data is invalid", %{conn: conn, swagger_schema: schema} do
      business_concept_version = insert(:business_concept_version)
      business_concept_id = business_concept_version.business_concept.id

      creation_attrs = %{
        name: nil
      }

      conn = post conn, business_concept_business_concept_alias_path(conn, :create, business_concept_id), business_concept_alias: creation_attrs
      validate_resp_schema(conn, schema, "BusinessConceptAliasResponse")
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  @tag authenticated_user: @admin_user_name
  describe "delete business_concept_alias" do
    test "deletes chosen business_concept_alias", %{conn: conn} do
      business_concept_version = insert(:business_concept_version)
      business_concept_id = business_concept_version.business_concept.id
      business_concept_alias = insert(:business_concept_alias, business_concept_id: business_concept_id)

      conn = delete conn, business_concept_alias_path(conn, :delete, business_concept_alias)
      assert response(conn, 204)

      conn = recycle_and_put_headers(conn)

      assert_error_sent 404, fn ->
        get conn, business_concept_alias_path(conn, :show, business_concept_alias)
      end
    end
  end
end
