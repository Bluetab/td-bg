defmodule TdBgWeb.BusinessConceptFilterControllerTest do
  use TdBgWeb.ConnCase
  use PhoenixSwagger.SchemaTest, "priv/static/swagger.json"

  setup %{conn: conn} do
    insert(:business_concept_version, content: %{"foo" => "bar"}, name: "Concept Name")

    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    @tag authentication: [role: "admin"]
    test "lists all filters (admin user)", %{conn: conn} do
      conn = get(conn, Routes.business_concept_filter_path(conn, :index))
      assert json_response(conn, 200)["data"] == %{}
    end

    @tag authentication: [user_name: "some_username"]
    test "lists all filters (non-admin user)", %{conn: conn} do
      conn = get(conn, Routes.business_concept_filter_path(conn, :index))
      assert json_response(conn, 200)["data"] == %{}
    end
  end
end
