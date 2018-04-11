defmodule TdBgWeb.BusinessConceptTypeControllerTest do
  use TdBgWeb.ConnCase
  use PhoenixSwagger.SchemaTest, "priv/static/swagger.json"

  alias TdBgWeb.ApiServices.MockTdAuthService
  alias Poison, as: JSON

  @bc_type_definition %{"some type" =>
    [%{"group" => "General", "max_size" => 100, "name" => "Formula", "required" => false, "type" => "string"},
     %{"group" => "General", "name" => "Format", "required" => true, "type" => "list", "values" => ["Date", "Numeric", "Amount", "Text"]}]
  }

  setup_all do
    start_supervised MockTdAuthService
    :ok
  end

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  @admin_user_name "app-admin"

  describe "List Business Concept Type" do
    @tag authenticated_user: @admin_user_name
    setup [:create_content_schema]

    test "lists all business_concepts types", %{conn: conn, swagger_schema: schema} do

      conn = get conn, business_concept_type_path(conn, :index)
      validate_resp_schema(conn, schema, "BusinessConceptTypesResponse")
      assert json_response(conn, 200)["data"] == [%{"type_name" => "some type"}]
    end
  end

  def create_content_schema(_) do
    json_schema = @bc_type_definition |> JSON.encode!
    path = Application.get_env(:td_bg, :bc_schema_location)
    File.write!(path, json_schema, [:write, :utf8])
  end
end
