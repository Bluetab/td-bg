defmodule TdBgWeb.BusinessConceptVersionControllerTest do
  use TdBgWeb.ConnCase
  use PhoenixSwagger.SchemaTest, "priv/static/swagger.json"

  import TdBgWeb.Authentication, only: :functions

  alias TdBg.BusinessConcepts.BusinessConcept
  alias TdBg.Permissions.MockPermissionResolver
  alias TdBgWeb.ApiServices.MockTdAuditService
  alias TdBgWeb.ApiServices.MockTdAuthService
  alias TdBgWeb.ApiServices.MockTdDdService
  @df_cache Application.get_env(:td_bg, :df_cache)

  setup_all do
    start_supervised(MockTdAuthService)
    start_supervised(MockTdAuditService)
    start_supervised(MockTdDdService)
    start_supervised(MockPermissionResolver)
    start_supervised(@df_cache)
    :ok
  end

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "show" do
    @tag :admin_authenticated
    test "shows the specified business_concept_version including it's name, description, domain and content",
         %{conn: conn} do
      create_template()
      business_concept_version =
        insert(
          :business_concept_version,
          content: %{"foo" => "bar"},
          name: "Concept Name",
          description: to_rich_text("The awesome concept")
        )

      conn = get(conn, business_concept_version_path(conn, :show, business_concept_version.id))
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
    @tag :admin_authenticated
    test "lists all business_concept_versions", %{conn: conn} do
      conn = get(conn, business_concept_version_path(conn, :index))
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "search" do
    @tag :admin_authenticated
    test "find business_concepts by id and status", %{conn: conn} do
      published = BusinessConcept.status().published
      draft = BusinessConcept.status().draft
      create_template()
      domain = insert(:domain)
      id = [create_version(domain, "one", draft).business_concept_id]
      id = [create_version(domain, "two", published).business_concept_id | id]
      id = [create_version(domain, "three", published).business_concept_id | id]

      conn =
        get(conn, business_concept_path(conn, :search), %{
          id: Enum.join(id, ","),
          status: published
        })

      assert 2 == length(json_response(conn, 200)["data"])
    end
  end

  describe "create business_concept" do
    @tag :admin_authenticated
    test "renders business_concept when data is valid", %{conn: conn, swagger_schema: schema} do
      domain = insert(:domain)
      create_template()
      creation_attrs = %{
        content: %{},
        type: "some_type",
        name: "Some name",
        description: to_rich_text("Some description"),
        domain_id: domain.id,
        in_progress: false
      }

      conn =
        post(
          conn,
          business_concept_version_path(conn, :create),
          business_concept_version: creation_attrs
        )

      validate_resp_schema(conn, schema, "BusinessConceptVersionResponse")
      assert %{"business_concept_id" => id} = json_response(conn, 201)["data"]

      conn = recycle_and_put_headers(conn)

      conn = get(conn, business_concept_path(conn, :show, id))
      validate_resp_schema(conn, schema, "BusinessConceptResponse")
      business_concept = json_response(conn, 200)["data"]

      %{
        id: id,
        last_change_by: Integer.mod(:binary.decode_unsigned("app-admin"), 100_000),
        version: 1
      }
      |> Enum.each(
        &assert business_concept |> Map.get(Atom.to_string(elem(&1, 0))) == elem(&1, 1)
      )

      creation_attrs
      |> Map.drop([:domain_id])
      |> Enum.each(
        &assert business_concept |> Map.get(Atom.to_string(elem(&1, 0))) == elem(&1, 1)
      )

      assert business_concept["domain"]["id"] == domain.id
      assert business_concept["domain"]["name"] == domain.name
    end

    @tag :admin_authenticated
    test "renders errors when data is invalid", %{conn: conn, swagger_schema: schema} do
      domain = insert(:domain)

      create_template(%{id: 0, name: "some_type", content: [], label: "label"})
      creation_attrs = %{
        content: %{},
        type: "some_type",
        name: nil,
        description: to_rich_text("Some description"),
        domain_id: domain.id,
        in_progress: false
      }

      conn =
        post(
          conn,
          business_concept_version_path(conn, :create),
          business_concept_version: creation_attrs
        )

      validate_resp_schema(conn, schema, "BusinessConceptVersionResponse")
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "index_by_name" do
    @tag :admin_authenticated
    test "find business concept by name", %{conn: conn} do
      published = BusinessConcept.status().published
      draft = BusinessConcept.status().draft
      create_template()
      domain = insert(:domain)
      id = [create_version(domain, "one", draft).business_concept.id]
      id = [create_version(domain, "two", published).business_concept.id | id]
      [create_version(domain, "two", published).business_concept.id | id]

      conn = get(conn, business_concept_version_path(conn, :index), %{query: "two"})
      assert 2 == length(json_response(conn, 200)["data"])

      conn = recycle_and_put_headers(conn)
      conn = get(conn, business_concept_version_path(conn, :index), %{query: "one"})
      assert 1 == length(json_response(conn, 200)["data"])
    end
  end

  describe "versions" do
    @tag :admin_authenticated
    test "lists business_concept_versions", %{conn: conn} do
      create_template()
      business_concept_version = insert(:business_concept_version)

      conn =
        get(
          conn,
          business_concept_version_business_concept_version_path(conn, :versions, business_concept_version.id)
        )

      [data | _] = json_response(conn, 200)["data"]
      assert data["name"] == business_concept_version.name
    end
  end

  describe "create new versions" do

    @tag :admin_authenticated
    test "create new version with modified template", %{
      conn: conn
    } do

      template_content = [%{"name" => "fieldname", "type" => "string", "cardinality" =>  "?"}]
      template = create_template(%{id: 0, name: "onefield", content: template_content, label: "label"})
      user = build(:user)
      business_concept =
        insert(:business_concept,
                type: template.name,
                last_change_by: user.id)
      business_concept_version =
        insert(
          :business_concept_version,
          business_concept: business_concept,
          last_change_by: user.id,
          status: BusinessConcept.status.published
        )

      updated_content = template
      |> Map.get(:content)
      |> Enum.reduce([], fn(field, acc) ->
            [Map.put(field, "cardinality", "1")|acc]
         end)

      update_attrs = Map.put(template, :content, updated_content)
      @df_cache.put_template(update_attrs)

      conn =
        post(
          conn,
          business_concept_version_business_concept_version_path(
            conn,
            :version,
            business_concept_version.id
          )
        )

        assert json_response(conn, 201)["data"]
    end
  end

  describe "update business_concept_version" do

    @tag :admin_authenticated
    test "renders business_concept_version when data is valid", %{
      conn: conn,
      swagger_schema: schema
    } do
      create_template()
      user = build(:user)
      business_concept_version = insert(:business_concept_version, last_change_by: user.id)
      business_concept_version_id = business_concept_version.id

      update_attrs = %{
        content: %{},
        name: "The new name",
        description: to_rich_text("The new description"),
        in_progress: false
      }

      conn =
        put(
          conn,
          business_concept_version_path(conn, :update, business_concept_version),
          business_concept_version: update_attrs
        )

      validate_resp_schema(conn, schema, "BusinessConceptVersionResponse")
      assert %{"id" => ^business_concept_version_id} = json_response(conn, 200)["data"]

      conn = recycle_and_put_headers(conn)
      conn = get(conn, business_concept_version_path(conn, :show, business_concept_version_id))
      validate_resp_schema(conn, schema, "BusinessConceptVersionResponse")

      updated_business_concept_version = json_response(conn, 200)["data"]

      update_attrs
      |> Enum.each(
        &assert updated_business_concept_version |> Map.get(Atom.to_string(elem(&1, 0))) ==
                  elem(&1, 1)
      )
    end
  end

  describe "data_structures" do
    @tag :admin_authenticated
    test "list data structures", %{conn: conn, swagger_schema: schema} do
      user = build(:user)
      business_concept_version = insert(:business_concept_version, last_change_by: user.id)
      business_concept_version_id = business_concept_version.id

      data_structure_1 = %{
        "id" => 1,
        "ou" => "ou 1",
        "system" => "system 1",
        "group" => "group 1",
        "name" => "name 1",
        "description" => to_rich_text("description 1")
      }

      data_structure_2 = %{
        "id" => 12,
        "ou" => "ou 1",
        "system" => "system 2",
        "group" => "group 2",
        "name" => "name 2",
        "description" => to_rich_text("description 2")
      }

      MockTdDdService.set_data_structure(data_structure_1)
      MockTdDdService.set_data_structure(data_structure_2)

      conn =
        get(
          conn,
          business_concept_version_business_concept_version_path(
            conn,
            :get_data_structures,
            business_concept_version_id
          )
        )

      validate_resp_schema(conn, schema, "DataStructuresResponse")
      response = json_response(conn, 200)["data"]
      response = Enum.sort_by(response, & &1["system"])

      assert Enum.at(response, 0)["system"] == data_structure_1["system"]
      assert Enum.at(response, 1)["system"] == data_structure_2["system"]
    end
  end

  describe "data_fielsd" do
    @tag :admin_authenticated
    test "list data structures", %{conn: conn, swagger_schema: schema} do
      user = build(:user)
      business_concept_version = insert(:business_concept_version, last_change_by: user.id)
      business_concept_version_id = business_concept_version.id

      data_field_1 = %{
        "id" => 1,
        "name" => "name 1"
      }

      data_field_2 = %{
        "id" => 2,
        "name" => "name 2"
      }

      data_structure = %{
        "ou" => business_concept_version.business_concept.domain.name,
        "data_fields" => [data_field_1, data_field_2]
      }

      MockTdDdService.set_data_field(data_structure)

      conn =
        get(
          conn,
          business_concept_version_business_concept_version_path(
            conn,
            :get_data_fields,
            business_concept_version_id,
            1234
          )
        )

      validate_resp_schema(conn, schema, "DataFieldsResponse")
      response = json_response(conn, 200)["data"]
      response = Enum.sort_by(response, & &1["system"])

      assert Enum.at(response, 0)["name"] == data_field_1["name"]
      assert Enum.at(response, 1)["name"] == data_field_2["name"]
    end
  end

  defp create_version(domain, name, status) do
    business_concept = insert(:business_concept, domain: domain)

    insert(
      :business_concept_version,
      business_concept: business_concept,
      name: name,
      status: status
    )
  end

  defp to_rich_text(plain) do
    %{"document" => plain}
  end

  def create_template do
    attrs =
      %{}
      |> Map.put(:id, 0)
      |> Map.put(:label, "some type")
      |> Map.put(:name, "some_type")
      |> Map.put(:content, [])

    @df_cache.put_template(attrs)
    :ok
  end
  def create_template(template) do
    @df_cache.put_template(template)
    template
  end
end
