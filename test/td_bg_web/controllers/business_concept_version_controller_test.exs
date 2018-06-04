defmodule TdBgWeb.BusinessConceptVersionControllerTest do
  use TdBgWeb.ConnCase
  use PhoenixSwagger.SchemaTest, "priv/static/swagger.json"

  import TdBgWeb.Authentication, only: :functions

  alias TdBgWeb.ApiServices.MockTdAuthService
  alias TdBgWeb.ApiServices.MockTdAuditService
  alias TdBgWeb.ApiServices.MockTdDdService
  alias TdBg.BusinessConcepts.BusinessConcept
  alias TdBg.Permissions
  alias Poison, as: JSON

  setup_all do
    start_supervised MockTdAuthService
    start_supervised MockTdAuditService
    start_supervised MockTdDdService
    :ok
  end

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "show" do
    @tag :admin_authenticated
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
    @tag :admin_authenticated
    test "lists all business_concept_versions", %{conn: conn} do
      conn = get conn, business_concept_version_path(conn, :index)
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "search" do
    @tag :admin_authenticated
    test "find business_concepts by id and status", %{conn: conn} do
      published = BusinessConcept.status.published
      draft = BusinessConcept.status.draft
      domain = insert(:domain)
      id = [create_version(domain, "one", draft).business_concept_id]
      id = [create_version(domain, "two", published).business_concept_id | id]
      id = [create_version(domain, "three", published).business_concept_id | id]
      conn = get conn, business_concept_path(conn, :search), %{id: Enum.join(id, ","), status: published}
      assert 2 == length(json_response(conn, 200)["data"])
    end
  end

  describe "create business_concept" do
    setup [:create_template]

    @tag :admin_authenticated
    test "renders business_concept when data is valid", %{conn: conn, swagger_schema: schema} do
      domain = insert(:domain)

      creation_attrs = %{
        content: %{},
        type: "some type",
        name: "Some name",
        description: "Some description",
        domain_id: domain.id
      }

      conn = post conn, business_concept_version_path(conn, :create), business_concept_version: creation_attrs
      validate_resp_schema(conn, schema, "BusinessConceptVersionResponse")
      assert %{"business_concept_id" => id} = json_response(conn, 201)["data"]

      conn = recycle_and_put_headers(conn)

      conn = get conn, business_concept_path(conn, :show, id)
      validate_resp_schema(conn, schema, "BusinessConceptResponse")
      business_concept = json_response(conn, 200)["data"]

      %{id: id, last_change_by: Integer.mod(:binary.decode_unsigned("app-admin"), 100_000), version: 1}
        |> Enum.each(&(assert business_concept |> Map.get(Atom.to_string(elem(&1, 0))) == elem(&1, 1)))

      creation_attrs
        |> Map.drop([:domain_id])
        |> Enum.each(&(assert business_concept |> Map.get(Atom.to_string(elem(&1, 0))) == elem(&1, 1)))

      assert business_concept["domain"]["id"] == domain.id
      assert business_concept["domain"]["name"] == domain.name
    end

    @tag :admin_authenticated
    test "renders errors when data is invalid", %{conn: conn, swagger_schema: schema} do
      domain = insert(:domain)
      creation_attrs = %{
        content: %{},
        type: "some type",
        name: nil,
        description: "Some description",
        domain_id: domain.id
      }
      conn = post conn, business_concept_version_path(conn, :create), business_concept_version: creation_attrs
      validate_resp_schema(conn, schema, "BusinessConceptVersionResponse")
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "index_by_name" do
    @tag :admin_authenticated
    test "find business concept by name", %{conn: conn} do
    published = BusinessConcept.status.published
      draft = BusinessConcept.status.draft
      domain = insert(:domain)
      id = [create_version(domain, "one", draft).business_concept.id]
      id = [create_version(domain, "two", published).business_concept.id | id]
      [create_version(domain, "two", published).business_concept.id | id]

      conn = get conn, business_concept_version_path(conn, :index), %{search_term: "two"}
      assert 2 == length(json_response(conn, 200)["data"])

      conn = recycle_and_put_headers(conn)
      conn = get conn, business_concept_version_path(conn, :index), %{search_term: "one"}
      assert 1 == length(json_response(conn, 200)["data"])
    end
  end

  describe "versions" do
    @tag :admin_authenticated
    test "lists business_concept_versions", %{conn: conn} do
      business_concept_version = insert(:business_concept_version)
      business_concept_id = business_concept_version.business_concept.id
      conn = get conn, business_concept_business_concept_version_path(conn, :versions, business_concept_id)
      [data|_] = json_response(conn, 200)["data"]
      assert data["name"] == business_concept_version.name
    end
  end

  describe "query_business_concept_taxonomy" do
    @tag :admin_authenticated
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

  describe "update business_concept_version" do
    setup [:create_template]

    @tag :admin_authenticated
    test "renders business_concept_version when data is valid", %{conn: conn, swagger_schema: schema} do
      user = build(:user)
      business_concept_version = insert(:business_concept_version, last_change_by:  user.id)
      business_concept_version_id = business_concept_version.id

      update_attrs = %{
        content: %{},
        name: "The new name",
        description: "The new description"
      }

      conn = put conn, business_concept_version_path(conn, :update, business_concept_version), business_concept_version: update_attrs
      validate_resp_schema(conn, schema, "BusinessConceptVersionResponse")
      assert %{"id" => ^business_concept_version_id} = json_response(conn, 200)["data"]

      conn = recycle_and_put_headers(conn)
      conn = get conn, business_concept_version_path(conn, :show, business_concept_version_id)
      validate_resp_schema(conn, schema, "BusinessConceptVersionResponse")

      updated_business_concept_version = json_response(conn, 200)["data"]

      update_attrs
        |> Enum.each(&(assert updated_business_concept_version |> Map.get(Atom.to_string(elem(&1, 0))) == elem(&1, 1)))
    end

    @tag :admin_authenticated
    test "renders errors when data is invalid", %{conn: conn, swagger_schema: schema} do
      user = build(:user)
      business_concept_version = insert(:business_concept_version, last_change_by:  user.id)
      business_concept_version_id = business_concept_version.id

      update_attrs = %{
        content: %{},
        name: nil,
        description: "The new description"
      }

      conn = put conn, business_concept_version_path(conn, :update, business_concept_version_id), business_concept_version: update_attrs
      validate_resp_schema(conn, schema, "BusinessConceptVersionResponse")
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "data_fields" do
    alias TdBgWeb.BusinessConceptDataFieldSupport

    @tag :admin_authenticated
    test "list data fields", %{conn: conn} do
      user = build(:user)
      business_concept_version = insert(:business_concept_version, last_change_by:  user.id)
      business_concept_version_id = business_concept_version.id

      conn = get conn, business_concept_version_business_concept_version_path(conn, :get_data_fields, business_concept_version_id)

      assert json_response(conn, 200)["data"] == []
    end

    @tag :admin_authenticated
    test "list data fields with result", %{conn: conn, swagger_schema: schema} do
      user = build(:user)
      business_concept_version = insert(:business_concept_version, last_change_by:  user.id)
      business_concept_id = business_concept_version.business_concept_id

      data_field = %{system: "system",
                     group: "group",
                     structure: "structure",
                     name: "name"}
      insert(:business_concept_data_field,
        business_concept: inspect(business_concept_id),
        data_field: BusinessConceptDataFieldSupport.normalize_data_field(data_field))

      conn = get conn, business_concept_version_business_concept_version_path(conn, :get_data_fields, business_concept_version.id)
      validate_resp_schema(conn, schema, "DataFieldsResponse")
      json_response =  json_response(conn, 200)["data"]
      assert length(json_response) == 1
      json_response = Enum.at(json_response, 0)
      assert json_response["system"] == data_field.system
      assert json_response["group"]  == data_field.group
      assert json_response["structure"]   == data_field.structure
      assert json_response["name"]  == data_field.name
    end

    @tag :admin_authenticated
    test "add data fields", %{conn: conn, swagger_schema: schema} do
      user = build(:user)
      business_concept_version = insert(:business_concept_version, last_change_by:  user.id)

      data_field1 = %{system: "system1",
                      group: "group1",
                      structure: "structure1",
                      name: "name1"}

      data_field2 = %{system: "system2",
                      group: "group2",
                      structure: "structure2",
                      name: "name2"}

      data_fields = [data_field1, data_field2]

      conn = post conn, business_concept_version_business_concept_version_path(conn, :set_data_fields, business_concept_version.id), data_fields: data_fields
      validate_resp_schema(conn, schema, "DataFieldsResponse")

      conn = recycle_and_put_headers(conn)

      conn = get conn, business_concept_version_business_concept_version_path(conn, :get_data_fields, business_concept_version.id)
      validate_resp_schema(conn, schema, "DataFieldsResponse")
      json_response =  json_response(conn, 200)["data"]
      assert length(json_response) == 2
      assert Enum.at(json_response, 0)["system"] == data_field1.system
      assert Enum.at(json_response, 1)["system"] == data_field2.system
    end
  end

  describe "data_structures" do
    @tag :admin_authenticated
    test "list data structures", %{conn: conn, swagger_schema: schema} do
      user = build(:user)
      business_concept_version = insert(:business_concept_version, last_change_by:  user.id)
      business_concept_version_id = business_concept_version.id

      data_structure_1 = %{
        "id" => 1,
        "system" => "system 1",
        "group" => "group 1",
        "name" => "name 1",
        "description" => "description 1"
      }

      data_structure_2 = %{
        "id" => 12,
        "system" => "system 2",
        "group" => "group 2",
        "name" => "name 2",
        "description" => "description 2"
      }

      MockTdDdService.set_data_structure(data_structure_1)
      MockTdDdService.set_data_structure(data_structure_2)

      conn = get conn, business_concept_version_business_concept_version_path(conn, :get_data_structures, business_concept_version_id)
      validate_resp_schema(conn, schema, "DataStructuresResponse")
      response = json_response(conn, 200)["data"]

      assert Enum.at(response, 0)["system"] == data_structure_1["system"]
      assert Enum.at(response, 1)["system"] == data_structure_2["system"]
    end
  end

  defp create_version(domain, name, status) do
    business_concept = insert(:business_concept, domain: domain)
    insert(:business_concept_version, business_concept: business_concept, name: name, status: status)
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
