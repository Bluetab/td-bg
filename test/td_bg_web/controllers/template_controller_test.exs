defmodule TdBgWeb.TemplateControllerTest do
  use TdBgWeb.ConnCase
  use PhoenixSwagger.SchemaTest, "priv/static/swagger.json"

  import TdBgWeb.Authentication, only: :functions

  alias TdBgWeb.ApiServices.MockTdAuthService
  alias TdBg.Templates
  alias TdBg.Templates.Template

  @create_attrs %{content: [], name: "some name"}
  @update_attrs %{content: [], name: "some updated name"}
  @invalid_attrs %{content: nil, name: nil}
  @domain_attrs %{name: "domain1", type: "type", parent_id: "", description: "description"}

  def fixture(:template) do
    {:ok, template} = Templates.create_template(@create_attrs)
    template
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
    test "lists all templates", %{conn: conn, swagger_schema: schema} do
      conn = get conn, template_path(conn, :index)
      validate_resp_schema(conn, schema, "TemplatesResponse")
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "create template" do
    @tag :admin_authenticated
    test "renders template when data is valid", %{conn: conn, swagger_schema: schema} do
      conn = post conn, template_path(conn, :create), template: @create_attrs
      validate_resp_schema(conn, schema, "TemplateResponse")
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = recycle_and_put_headers(conn)
      conn = get conn, template_path(conn, :show, id)
      validate_resp_schema(conn, schema, "TemplateResponse")
      assert json_response(conn, 200)["data"] == %{
        "id" => id,
        "content" => [],
        "name" => "some name"}
    end

    @tag :admin_authenticated
    test "renders errors when data is invalid", %{conn: conn} do
      conn = post conn, template_path(conn, :create), template: @invalid_attrs
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update template" do
    setup [:create_template]

    @tag :admin_authenticated
    test "renders template when data is valid", %{conn: conn, swagger_schema: schema, template: %Template{id: id} = template} do
      conn = put conn, template_path(conn, :update, template), template: @update_attrs
      validate_resp_schema(conn, schema, "TemplateResponse")
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = recycle_and_put_headers(conn)
      conn = get conn, template_path(conn, :show, id)
      validate_resp_schema(conn, schema, "TemplateResponse")
      assert json_response(conn, 200)["data"] == %{
        "id" => id,
        "content" => [],
        "name" => "some updated name"}
    end

    @tag :admin_authenticated
    test "renders errors when data is invalid", %{conn: conn, template: template} do
      conn = put conn, template_path(conn, :update, template), template: @invalid_attrs
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete template" do
    setup [:create_template]

    @tag :admin_authenticated
    test "deletes chosen template", %{conn: conn, template: template} do
      conn = delete conn, template_path(conn, :delete, template)
      assert response(conn, 204)
      conn = recycle_and_put_headers(conn)
      assert_error_sent 404, fn ->
        get conn, template_path(conn, :show, template)
      end
    end
  end

  describe "domain templates" do

    @tag :admin_authenticated
    test "relate domain and template", %{conn: conn, swagger_schema: schema} do
      conn = post conn, template_path(conn, :create), template: @create_attrs
      validate_resp_schema(conn, schema, "TemplateResponse")

      conn = recycle_and_put_headers(conn)
      conn = post conn, domain_path(conn, :create), domain: @domain_attrs
      validate_resp_schema(conn, schema, "DomainResponse")
      assert %{"id" => domain_id} = json_response(conn, 201)["data"]

      conn = recycle_and_put_headers(conn)
      conn = get conn, template_path(conn, :index)
      templates = json_response(conn, 200)["data"]

      conn = recycle_and_put_headers(conn)
      conn = post conn, template_path(conn, :add_templates_to_domain, domain_id), templates: templates
      validate_resp_schema(conn, schema, "TemplatesResponse")

      conn = recycle_and_put_headers(conn)
      conn = get conn, template_path(conn, :get_domain_templates, domain_id)
      validate_resp_schema(conn, schema, "TemplatesResponse")
      stored_templates = json_response(conn, 200)["data"]
      stored_templates = Enum.sort(stored_templates, &(Map.get(&1, "name") < Map.get(&2, "name")))

      assert templates == stored_templates
    end
  end

  defp create_template(_) do
    template = fixture(:template)
    {:ok, template: template}
  end
end
