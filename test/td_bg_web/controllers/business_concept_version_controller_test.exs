defmodule TdBgWeb.BusinessConceptVersionControllerTest do
  use TdBgWeb.ConnCase
  use PhoenixSwagger.SchemaTest, "priv/static/swagger.json"

  import TdBgWeb.Authentication, only: :functions
  import TdBgWeb.User, only: :functions

  alias TdBg.BusinessConcepts.BusinessConcept
  alias TdBg.Permissions.MockPermissionResolver
  alias TdBgWeb.ApiServices.MockTdAuditService
  alias TdBgWeb.ApiServices.MockTdAuthService
  alias TdCache.TemplateCache

  setup_all do
    start_supervised(MockTdAuthService)
    start_supervised(MockTdAuditService)
    start_supervised(MockPermissionResolver)
    :ok
  end

  @user_name "user"

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

      conn =
        get(conn, Routes.business_concept_version_path(conn, :show, business_concept_version.id))

      data = json_response(conn, 200)["data"]
      assert data["name"] == business_concept_version.name
      assert data["description"] == business_concept_version.description
      assert data["business_concept_id"] == business_concept_version.business_concept.id
      assert data["content"] == business_concept_version.content
      assert data["domain"]["id"] == business_concept_version.business_concept.domain.id
      assert data["domain"]["name"] == business_concept_version.business_concept.domain.name
    end

    @tag authenticated_user: @user_name
    test "show with actions",
         %{conn: conn} do
      user = create_user(@user_name)
      domain_create = insert(:domain, id: :rand.uniform(100_000_000))
      role_create = get_role_by_name("create")

      MockPermissionResolver.create_acl_entry(%{
        principal_id: user.id,
        principal_type: "user",
        resource_id: domain_create.id,
        resource_type: "domain",
        role_id: role_create.id,
        role_name: role_create.name
      })

      business_concept = insert(:business_concept, domain: domain_create)

      version = insert(
        :business_concept_version,
        business_concept: business_concept,
        name: "name"
      )

      conn =
        get(conn, Routes.business_concept_version_path(conn, :show, version.id))
      data = json_response(conn, 200)["_actions"]

      assert Map.has_key?(data, "create_link")

      MockPermissionResolver.clean()
    end
  end

  describe "index" do
    @tag :admin_authenticated
    test "lists all business_concept_versions", %{conn: conn} do
      conn = get(conn, Routes.business_concept_version_path(conn, :index))
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "search" do
    @tag :admin_authenticated
    test "find business_concepts by status", %{conn: conn} do
      published = BusinessConcept.status().published
      draft = BusinessConcept.status().draft
      create_template()
      domain = insert(:domain)
      create_version(domain, "one", draft).business_concept_id
      create_version(domain, "two", published).business_concept_id
      create_version(domain, "three", published).business_concept_id

      conn =
        post(conn, Routes.business_concept_version_path(conn, :search), %{
          filters: %{status: ["published"]}
        })

      assert 2 == length(json_response(conn, 200)["data"])
    end

    @tag authenticated_user: @user_name
    test "find only linkable concepts", %{conn: conn} do
      user = create_user(@user_name)
      domain_watch = insert(:domain)
      domain_create = insert(:domain)
      role_watch = get_role_by_name("watch")
      role_create = get_role_by_name("create")

      MockPermissionResolver.create_acl_entry(%{
        principal_id: user.id,
        principal_type: "user",
        resource_id: domain_watch.id,
        resource_type: "domain",
        role_id: role_watch.id,
        role_name: role_watch.name
      })

      MockPermissionResolver.create_acl_entry(%{
        principal_id: user.id,
        principal_type: "user",
        resource_id: domain_create.id,
        resource_type: "domain",
        role_id: role_create.id,
        role_name: role_create.name
      })

      draft = BusinessConcept.status().draft
      create_version(domain_watch, "bc_watch", draft).business_concept_id
      bc_create_id = create_version(domain_create, "bc_create", draft).business_concept_id

      conn =
        post(conn, Routes.business_concept_version_path(conn, :search), %{
          only_linkable: true
        })

      data = json_response(conn, 200)["data"]
      assert 1 == length(data)

      assert bc_create_id ==
               data
               |> Enum.at(0)
               |> Map.get("business_concept_id")
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
          Routes.business_concept_version_path(conn, :create),
          business_concept_version: creation_attrs
        )

      validate_resp_schema(conn, schema, "BusinessConceptVersionResponse")
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = recycle_and_put_headers(conn)

      conn = get(conn, Routes.business_concept_version_path(conn, :show, id))
      validate_resp_schema(conn, schema, "BusinessConceptVersionResponse")
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

      create_template(%{id: 0, name: "some_type", content: [], label: "label", scope: "test"})

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
          Routes.business_concept_version_path(conn, :create),
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

      conn = get(conn, Routes.business_concept_version_path(conn, :index), %{query: "two"})
      assert 2 == length(json_response(conn, 200)["data"])

      conn = recycle_and_put_headers(conn)
      conn = get(conn, Routes.business_concept_version_path(conn, :index), %{query: "one"})
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
          Routes.business_concept_version_business_concept_version_path(
            conn,
            :versions,
            business_concept_version.id
          )
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
      template_content = [%{"name" => "fieldname", "type" => "string", "cardinality" => "?"}]

      template =
        create_template(%{
          id: 0,
          name: "onefield",
          content: template_content,
          label: "label",
          scope: "test"
        })

      user = build(:user)

      business_concept =
        insert(:business_concept,
          type: template.name,
          last_change_by: user.id
        )

      business_concept_version =
        insert(
          :business_concept_version,
          business_concept: business_concept,
          last_change_by: user.id,
          status: BusinessConcept.status().published
        )

      updated_content =
        template
        |> Map.get(:content)
        |> Enum.reduce([], fn field, acc ->
          [Map.put(field, "cardinality", "1") | acc]
        end)

      update_attrs = Map.put(template, :content, updated_content)
      TemplateCache.put(update_attrs)

      conn =
        post(
          conn,
          Routes.business_concept_version_business_concept_version_path(
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
          Routes.business_concept_version_path(conn, :update, business_concept_version),
          business_concept_version: update_attrs
        )

      validate_resp_schema(conn, schema, "BusinessConceptVersionResponse")
      assert %{"id" => ^business_concept_version_id} = json_response(conn, 200)["data"]

      conn = recycle_and_put_headers(conn)

      conn =
        get(conn, Routes.business_concept_version_path(conn, :show, business_concept_version_id))

      validate_resp_schema(conn, schema, "BusinessConceptVersionResponse")

      updated_business_concept_version = json_response(conn, 200)["data"]

      update_attrs
      |> Enum.each(
        &assert updated_business_concept_version |> Map.get(Atom.to_string(elem(&1, 0))) ==
                  elem(&1, 1)
      )
    end
  end

  describe "bulk_update" do
    @tag :admin_authenticated
    test "bulk update of business concept", %{conn: conn} do
      domain = insert(:domain, name: "domain1")
      domain_new = insert(:domain, name: "domain_new")
      business_concept = insert(:business_concept, domain: domain, type: "template_test")

      TemplateCache.put(%{
        name: "template_test",
        content: [
          %{
            "name" => "Field1",
            "type" => "string",
            "group" => "Multiple Group",
            "label" => "Multiple 1",
            "values" => nil,
            "cardinality" => "1"
          },
          %{
            "name" => "Field2",
            "type" => "string",
            "group" => "Multiple Group",
            "label" => "Multiple 1",
            "values" => nil,
            "cardinality" => "1"
          }
        ],
        scope: "test",
        label: "template_label",
        id: "999"
      })

      insert(
        :business_concept_version,
        business_concept: business_concept,
        name: "version_draft",
        status: BusinessConcept.status().draft
      )

      version_published =
        insert(
          :business_concept_version,
          business_concept: business_concept,
          name: "version_published",
          status: BusinessConcept.status().published
        )

      conn =
        post(conn, Routes.business_concept_version_path(conn, :bulk_update), %{
          "update_attributes" => %{
            "domain_id" => domain_new.id
          },
          "search_params" => %{"filters" => %{"status" => ["published"]}}
        })

      %{"message" => updated_version_ids} = json_response(conn, 200)["data"]
      assert Enum.at(updated_version_ids, 0) == version_published.id
    end

    @tag :admin_authenticated
    test "bulk update of business concept with no domain", %{conn: conn} do
      domain = insert(:domain, name: "domain1")
      business_concept = insert(:business_concept, domain: domain, type: "template_test")

      TemplateCache.put(%{
        name: "template_test",
        content: [
          %{
            "name" => "Field1",
            "type" => "string",
            "group" => "Multiple Group",
            "label" => "Multiple 1",
            "values" => nil,
            "cardinality" => "1"
          },
          %{
            "name" => "Field2",
            "type" => "string",
            "group" => "Multiple Group",
            "label" => "Multiple 1",
            "values" => nil,
            "cardinality" => "1"
          }
        ],
        scope: "test",
        label: "template_label",
        id: "999"
      })

      insert(
        :business_concept_version,
        business_concept: business_concept,
        name: "version_draft",
        status: BusinessConcept.status().draft
      )

      insert(
        :business_concept_version,
        business_concept: business_concept,
        name: "version_published",
        status: BusinessConcept.status().published
      )

      conn =
        post(conn, Routes.business_concept_version_path(conn, :bulk_update), %{
          "update_attributes" => %{
            "domain_id" => 78_482
          },
          "search_params" => %{"filters" => %{"status" => ["published"]}}
        })

      %{"error" => error} = json_response(conn, 422)
      assert error == "missing_domain"
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
      |> Map.put(:scope, "test")
      |> Map.put(:content, [])

    TemplateCache.put(attrs)
    :ok
  end

  def create_template(template) do
    TemplateCache.put(template)
    template
  end
end
