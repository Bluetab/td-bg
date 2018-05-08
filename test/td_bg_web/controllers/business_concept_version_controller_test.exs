defmodule TdBgWeb.BusinessConceptVersionControllerTest do
  use TdBgWeb.ConnCase
  use PhoenixSwagger.SchemaTest, "priv/static/swagger.json"

  import TdBgWeb.Authentication, only: :functions

  alias TdBgWeb.ApiServices.MockTdAuthService
  alias Poison, as: JSON

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
