defmodule TdBgWeb.BusinessConceptVersionControllerTest do
  use TdBgWeb.ConnCase
  use PhoenixSwagger.SchemaTest, "priv/static/swagger.json"

  alias TdBg.Cache.ConceptLoader
  alias TdBg.Cache.DomainLoader
  alias TdBg.Search.IndexWorker

  setup_all do
    start_supervised(ConceptLoader)
    start_supervised(DomainLoader)
    start_supervised(IndexWorker)
    :ok
  end

  @user_name "some_username"
  @template_name "foo_template"

  setup context do
    case context[:template] do
      nil ->
        :ok

      true ->
        Templates.create_template()

      content ->
        Templates.create_template(%{
          id: 0,
          name: @template_name,
          label: "label",
          scope: "test",
          content: content
        })
    end

    [domain: insert(:domain)]
  end

  describe "GET /api/business_concepts/:business_concept_id/versions/:id" do
    @tag authentication: [role: "admin"]
    @tag :template
    test "shows the specified business_concept_version including it's name, description, domain and content",
         %{conn: conn} do
      business_concept_version =
        insert(
          :business_concept_version,
          content: %{"foo" => "bar"},
          name: "Concept Name",
          description: to_rich_text("The awesome concept")
        )

      conn =
        get(
          conn,
          Routes.business_concept_business_concept_version_path(
            conn,
            :show,
            business_concept_version.business_concept_id,
            "current"
          )
        )

      data = json_response(conn, 200)["data"]
      assert data["name"] == business_concept_version.name
      assert data["description"] == business_concept_version.description
      assert data["business_concept_id"] == business_concept_version.business_concept.id
      assert data["content"] == business_concept_version.content
      assert data["domain"]["id"] == business_concept_version.business_concept.domain.id
      assert data["domain"]["name"] == business_concept_version.business_concept.domain.name

      conn =
        get(
          conn,
          Routes.business_concept_business_concept_version_path(
            conn,
            :show,
            business_concept_version.business_concept_id,
            business_concept_version.id
          )
        )

      data = json_response(conn, 200)["data"]
      assert data["name"] == business_concept_version.name
      assert data["description"] == business_concept_version.description
      assert data["business_concept_id"] == business_concept_version.business_concept.id
      assert data["content"] == business_concept_version.content
      assert data["domain"]["id"] == business_concept_version.business_concept.domain.id
      assert data["domain"]["name"] == business_concept_version.business_concept.domain.name

      conn =
        get(
          conn,
          Routes.business_concept_business_concept_version_path(
            conn,
            :show,
            business_concept_version.business_concept_id + 1,
            "current"
          )
        )

      assert %{"errors" => %{"detail" => "Not found"}} = json_response(conn, 404)
    end

    @tag authentication: [role: "admin"]
    @tag :template
    test "shows the domains in which it has been shared",
         %{conn: conn} do
      d1 = %{id: d1_id} = insert(:domain)
      d2 = %{id: d2_id} = insert(:domain)

      %{business_concept: %{id: concept_id} = concept} =
        insert(
          :business_concept_version,
          content: %{"foo" => "bar"}
        )

      insert(:shared_concept, business_concept: concept, domain: d1)
      insert(:shared_concept, business_concept: concept, domain: d2)

      conn =
        get(
          conn,
          Routes.business_concept_business_concept_version_path(
            conn,
            :show,
            concept_id,
            "current"
          )
        )

      link = "/api/business_concepts/#{concept_id}/shared_domains"

      %{
        "_embedded" => %{"shared_to" => [%{"id" => ^d1_id}, %{"id" => ^d2_id}]},
        "actions" => %{
          "share" => %{
            "href" => ^link,
            "method" => "PATCH",
            "input" => %{}
          }
        }
      } = json_response(conn, 200)["data"]
    end

    @tag authentication: [user_name: @user_name]
    @tag :template
    test "show with actions", %{
      conn: conn,
      domain: %{id: domain_id} = domain,
      claims: %{user_id: user_id}
    } do
      create_acl_entry(user_id, "domain", domain_id, "create")

      %{id: id, business_concept_id: business_concept_id} =
        insert(:business_concept_version,
          business_concept: build(:business_concept, domain: domain)
        )

      assert %{"_actions" => actions} =
               conn
               |> get(
                 Routes.business_concept_business_concept_version_path(
                   conn,
                   :show,
                   business_concept_id,
                   id
                 )
               )
               |> json_response(:ok)

      assert Map.has_key?(actions, "create_concept_link")
      assert Map.has_key?(actions, "create_structure_link")
    end

    @tag authentication: [user_name: @user_name]
    @tag :template
    test "user with manage_business_concepts_domain permission has update_domain action", %{
      conn: conn,
      domain: %{id: domain_id} = domain,
      claims: %{user_id: user_id}
    } do
      create_acl_entry(user_id, "domain", domain_id, "manage_bc_domain")

      %{id: id, business_concept_id: business_concept_id} =
        insert(:business_concept_version,
          business_concept: build(:business_concept, domain: domain)
        )

      assert %{"_actions" => actions} =
               conn
               |> get(
                 Routes.business_concept_business_concept_version_path(
                   conn,
                   :show,
                   business_concept_id,
                   id
                 )
               )
               |> json_response(:ok)

      assert Map.has_key?(actions, "update_domain")
    end

    @tag authentication: [role: "admin"]
    @tag :template
    test "admin has update_domain action", %{
      conn: conn,
      domain: domain
    } do
      %{id: id, business_concept_id: business_concept_id} =
        insert(:business_concept_version,
          business_concept: build(:business_concept, domain: domain)
        )

      assert %{"_actions" => actions} =
               conn
               |> get(
                 Routes.business_concept_business_concept_version_path(
                   conn,
                   :show,
                   business_concept_id,
                   id
                 )
               )
               |> json_response(:ok)

      assert Map.has_key?(actions, "update_domain")
    end

    @tag authentication: [user_name: @user_name]
    @tag :template
    test "includes share action if non-admin user has :share_with_domain permission", %{
      conn: conn,
      domain: %{id: domain_id} = domain,
      claims: %{user_id: user_id}
    } do
      create_acl_entry(user_id, "domain", domain_id, [
        :update_business_concept,
        :view_draft_business_concepts,
        :share_with_domain
      ])

      %{id: id, business_concept_id: business_concept_id} =
        insert(:business_concept_version,
          business_concept: build(:business_concept, domain: domain)
        )

      conn =
        get(
          conn,
          Routes.business_concept_business_concept_version_path(
            conn,
            :show,
            business_concept_id,
            id
          )
        )

      link = "/api/business_concepts/#{business_concept_id}/shared_domains"

      %{
        "actions" => %{
          "share" => %{
            "href" => ^link,
            "method" => "PATCH",
            "input" => %{}
          }
        }
      } = json_response(conn, 200)["data"]
    end

    @tag authentication: [user_name: @user_name]
    @tag :template
    test "does not include share action if non-admin user does not have :share_with_domain permission",
         %{
           conn: conn,
           domain: %{id: domain_id} = domain,
           claims: %{user_id: user_id}
         } do
      create_acl_entry(user_id, "domain", domain_id, [
        :update_business_concept,
        :view_draft_business_concepts
      ])

      %{id: id, business_concept_id: business_concept_id} =
        insert(:business_concept_version,
          business_concept: build(:business_concept, domain: domain)
        )

      conn =
        get(
          conn,
          Routes.business_concept_business_concept_version_path(
            conn,
            :show,
            business_concept_id,
            id
          )
        )

      assert false == Map.get(json_response(conn, 200)["data"]["actions"], "share")
    end

    @tag authentication: [user_name: @user_name]
    @tag :template
    test "show actions in shared domains", %{
      conn: conn,
      domain: domain,
      claims: %{user_id: user_id}
    } do
      shared_to = %{id: domain_id} = insert(:domain)
      create_acl_entry(user_id, "domain", domain_id, "create")

      %{id: id, business_concept_id: business_concept_id} =
        insert(:business_concept_version,
          business_concept: build(:business_concept, domain: domain, shared_to: [shared_to])
        )

      assert %{"_actions" => actions} =
               conn
               |> get(
                 Routes.business_concept_business_concept_version_path(
                   conn,
                   :show,
                   business_concept_id,
                   id
                 )
               )
               |> json_response(:ok)

      assert Map.has_key?(actions, "create_structure_link")
      refute Map.has_key?(actions, "create_concept_link")
    end

    @tag authentication: [user_name: @user_name]
    @tag :template
    test "shows concept when we have permissions over shared domain", %{
      conn: conn,
      domain: domain,
      claims: %{user_id: user_id}
    } do
      %{id: domain_id} = shared = insert(:domain)

      %{id: id, business_concept_id: business_concept_id} =
        insert(:business_concept_version,
          business_concept: build(:business_concept, domain: domain, shared_to: [shared])
        )

      create_acl_entry(user_id, "domain", domain_id, "create")

      assert %{
               "data" => %{
                 "id" => ^id,
                 "business_concept_id" => ^business_concept_id,
                 "_embedded" => %{
                   "shared_to" => [%{"id" => ^domain_id}]
                 }
               }
             } =
               conn
               |> get(
                 Routes.business_concept_business_concept_version_path(
                   conn,
                   :show,
                   business_concept_id,
                   id
                 )
               )
               |> json_response(:ok)
    end
  end

  describe "GET /api/business_concept_versions" do
    setup do
      insert(:business_concept_version)
      :ok
    end

    @tag authentication: [role: "admin"]
    test "admin user can list all business_concept_versions", %{conn: conn} do
      assert %{"data" => [_]} =
               conn
               |> get(Routes.business_concept_version_path(conn, :index))
               |> json_response(:ok)
    end

    @tag authentication: [role: "service"]
    test "service account can list all business_concept_versions", %{conn: conn} do
      assert %{"data" => [_]} =
               conn
               |> get(Routes.business_concept_version_path(conn, :index))
               |> json_response(:ok)
    end
  end

  describe "POST /api/business_concept_versions/search" do
    @tag authentication: [role: "admin"]
    test "find business_concepts by status", %{conn: conn, domain: domain} do
      create_version(domain, "one", "draft")
      create_version(domain, "two", "published")
      create_version(domain, "three", "published")

      filter_params = %{"status" => ["published"]}

      assert %{"data" => [_, _]} =
               conn
               |> post(Routes.business_concept_version_path(conn, :search), filters: filter_params)
               |> json_response(:ok)
    end

    @tag authentication: [role: "service"]
    test "service account filter by status", %{conn: conn, domain: domain} do
      create_version(domain, "one", "draft")
      create_version(domain, "two", "published")
      create_version(domain, "three", "published")

      filter_params = %{"status" => ["published"]}

      assert %{"data" => [_, _]} =
               conn
               |> post(Routes.business_concept_version_path(conn, :search), filters: filter_params)
               |> json_response(:ok)
    end

    @tag authentication: [user_name: @user_name]
    test "find only linkable concepts", %{conn: conn, claims: %{user_id: user_id}} do
      domain_watch = insert(:domain)
      domain_create = insert(:domain)

      create_acl_entry(user_id, "domain", domain_watch.id, "watch")
      create_acl_entry(user_id, "domain", domain_create.id, "create")

      create_version(domain_watch, "bc_watch", "draft")
      %{business_concept_id: id} = create_version(domain_create, "bc_create", "draft")

      assert %{"data" => data} =
               conn
               |> post(Routes.business_concept_version_path(conn, :search), only_linkable: true)
               |> json_response(:ok)

      assert [%{"business_concept_id" => ^id}] = data
    end
  end

  describe "create business_concept" do
    @tag authentication: [role: "user"]
    @tag :template
    test "renders business_concept when data is valid", %{
      conn: conn,
      claims: %{user_id: user_id},
      swagger_schema: schema
    } do
      domain = insert(:domain)
      create_acl_entry(user_id, "domain", domain.id, "create")

      creation_attrs = %{
        "content" => %{},
        "type" => "some_type",
        "name" => "Some name",
        "description" => to_rich_text("Some description"),
        "domain_id" => domain.id,
        "in_progress" => false
      }

      assert %{"data" => data} =
               conn
               |> post(
                 Routes.business_concept_version_path(conn, :create),
                 business_concept_version: creation_attrs
               )
               |> validate_resp_schema(schema, "BusinessConceptVersionResponse")
               |> json_response(:created)

      assert %{"id" => id, "business_concept_id" => business_concept_id} = data

      assert %{"data" => data} =
               conn
               |> get(
                 Routes.business_concept_business_concept_version_path(
                   conn,
                   :show,
                   business_concept_id,
                   id
                 )
               )
               |> validate_resp_schema(schema, "BusinessConceptVersionResponse")
               |> json_response(:ok)

      assert %{"id" => ^id, "last_change_by" => _, "version" => 1} = data

      creation_attrs
      |> Map.delete("domain_id")
      |> Enum.each(fn {k, v} -> assert data[k] == v end)

      assert data["domain"]["id"] == domain.id
      assert data["domain"]["name"] == domain.name
    end

    @tag authentication: [role: "user"]
    @tag :template
    test "doesn't allow concept creation when not in domain", %{
      conn: conn,
      swagger_schema: schema
    } do
      domain = insert(:domain)

      creation_attrs = %{
        "content" => %{},
        "type" => "some_type",
        "name" => "Some name",
        "description" => to_rich_text("Some description"),
        "domain_id" => domain.id,
        "in_progress" => false
      }

      assert conn
             |> post(
               Routes.business_concept_version_path(conn, :create),
               business_concept_version: creation_attrs
             )
             |> validate_resp_schema(schema, "BusinessConceptVersionResponse")
             |> json_response(:forbidden)
    end

    @tag authentication: [role: "admin"]
    test "renders errors when data is invalid", %{conn: conn, swagger_schema: schema} do
      domain = insert(:domain)

      creation_attrs = %{
        content: %{},
        type: "some_type",
        name: nil,
        description: to_rich_text("Some description"),
        domain_id: domain.id,
        in_progress: false
      }

      assert %{"errors" => [%{"name" => _}]} =
               conn
               |> post(
                 Routes.business_concept_version_path(conn, :create),
                 business_concept_version: creation_attrs
               )
               |> validate_resp_schema(schema, "BusinessConceptVersionResponse")
               |> json_response(422)
    end
  end

  describe "index_by_name" do
    @tag authentication: [role: "admin"]
    test "find business concept by name", %{conn: conn} do
      domain = insert(:domain)
      id = [create_version(domain, "one", "draft").business_concept.id]
      id = [create_version(domain, "two", "published").business_concept.id | id]
      [create_version(domain, "two", "published").business_concept.id | id]

      assert %{"data" => data} =
               conn
               |> get(Routes.business_concept_version_path(conn, :index), %{query: "two"})
               |> json_response(:ok)

      assert length(data) == 2

      assert %{"data" => data} =
               conn
               |> get(Routes.business_concept_version_path(conn, :index), %{query: "one"})
               |> json_response(:ok)

      assert length(data) == 1
    end
  end

  describe "index by business concept id" do
    @tag authentication: [role: "admin"]
    test "lists business_concept_versions", %{conn: conn} do
      business_concept_version = insert(:business_concept_version)

      conn =
        get(
          conn,
          Routes.business_concept_business_concept_version_path(
            conn,
            :index,
            business_concept_version.business_concept.id
          )
        )

      [data | _] = json_response(conn, 200)["data"]
      assert data["name"] == business_concept_version.name
    end
  end

  describe "create new versions" do
    @tag authentication: [role: "admin"]
    test "create new version with modified template", %{
      conn: conn
    } do
      template_content = [
        %{
          "name" => "group",
          "fields" => [%{"name" => "fieldname", "type" => "string", "cardinality" => "?"}]
        }
      ]

      template =
        Templates.create_template(%{
          id: 0,
          name: "onefield",
          content: template_content,
          label: "label",
          scope: "test"
        })

      %{user_id: user_id} = build(:claims)

      business_concept =
        insert(:business_concept,
          type: template.name,
          last_change_by: user_id
        )

      business_concept_version =
        insert(
          :business_concept_version,
          business_concept: business_concept,
          last_change_by: user_id,
          status: "published"
        )

      updated_content =
        template
        |> Map.get(:content)
        |> Enum.reduce([], fn field, acc ->
          [Map.put(field, "cardinality", "1") | acc]
        end)

      template
      |> Map.put(:content, updated_content)
      |> Templates.create_template()

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
    @tag authentication: [role: "admin"]
    @tag :template
    test "renders business_concept_version when data is valid", %{
      conn: conn,
      swagger_schema: schema
    } do
      %{user_id: user_id} = build(:claims)

      business_concept_version = insert(:business_concept_version, last_change_by: user_id)

      business_concept_version_id = business_concept_version.id
      business_concept_id = business_concept_version.business_concept_id

      update_attrs = %{
        "content" => %{},
        "name" => "The new name",
        "description" => to_rich_text("The new description"),
        "in_progress" => false
      }

      assert %{"data" => data} =
               conn
               |> put(
                 Routes.business_concept_version_path(conn, :update, business_concept_version),
                 business_concept_version: update_attrs
               )
               |> validate_resp_schema(schema, "BusinessConceptVersionResponse")
               |> json_response(:ok)

      assert %{"id" => ^business_concept_version_id} = data

      assert %{"data" => data} =
               conn
               |> get(
                 Routes.business_concept_business_concept_version_path(
                   conn,
                   :show,
                   business_concept_id,
                   business_concept_version_id
                 )
               )
               |> validate_resp_schema(schema, "BusinessConceptVersionResponse")
               |> json_response(:ok)

      Enum.each(update_attrs, fn {k, v} -> assert data[k] == v end)
    end
  end

  describe "update business_concept domain" do
    @tag authentication: [role: "admin"]
    @tag :template
    test "renders business_concept_version with domain change", %{
      conn: conn,
      swagger_schema: schema
    } do
      business_concept_version = insert(:business_concept_version)

      %{id: domain_id} = insert(:domain)

      assert %{"data" => data} =
               conn
               |> post(
                 Routes.business_concept_version_business_concept_version_path(
                   conn,
                   :update_domain,
                   business_concept_version
                 ),
                 domain_id: domain_id
               )
               |> validate_resp_schema(schema, "BusinessConceptVersionResponse")
               |> json_response(:ok)

      assert %{"domain" => %{"id" => ^domain_id}} = data
    end

    @tag authentication: [role: "user"]
    @tag :template
    test "doesn't allow concept update when in domain without permission", %{
      conn: conn,
      swagger_schema: schema
    } do
      business_concept_version = insert(:business_concept_version)

      %{id: domain_id} = insert(:domain)

      assert conn
             |> post(
               Routes.business_concept_version_business_concept_version_path(
                 conn,
                 :update_domain,
                 business_concept_version
               ),
               domain_id: domain_id
             )
             |> validate_resp_schema(schema, "BusinessConceptVersionResponse")
             |> json_response(:forbidden)
    end

    @tag authentication: [
           role: "user",
           permissions: [:update_business_concept, :manage_business_concepts_domain]
         ]
    @tag :template
    test "user with permission in new domain, can update business concept domain", %{
      conn: conn,
      permissions_domain: domain,
      claims: %{user_id: user_id},
      swagger_schema: schema
    } do
      business_concept_version =
        insert(:business_concept_version,
          business_concept: build(:business_concept, domain: domain)
        )

      %{id: domain_id} = insert(:domain)

      create_acl_entry(user_id, "domain", domain_id, [
        :update_business_concept,
        :manage_business_concepts_domain
      ])

      assert %{"data" => data} =
               conn
               |> post(
                 Routes.business_concept_version_business_concept_version_path(
                   conn,
                   :update_domain,
                   business_concept_version
                 ),
                 domain_id: domain_id
               )
               |> validate_resp_schema(schema, "BusinessConceptVersionResponse")
               |> json_response(:ok)

      assert %{"domain" => %{"id" => ^domain_id}} = data
    end

    @tag authentication: [
           role: "user",
           permissions: [:update_business_concept, :manage_business_concepts_domain]
         ]
    @tag :template
    test "user without permission in new domain, cannot update business concept domain", %{
      conn: conn,
      permissions_domain: domain,
      claims: %{user_id: user_id},
      swagger_schema: schema
    } do
      business_concept_version =
        insert(:business_concept_version,
          business_concept: build(:business_concept, domain: domain)
        )

      %{id: domain_id} = insert(:domain)

      create_acl_entry(user_id, "domain", domain_id, [:update_business_concept])

      assert conn
             |> post(
               Routes.business_concept_version_business_concept_version_path(
                 conn,
                 :update_domain,
                 business_concept_version
               ),
               domain_id: domain_id
             )
             |> validate_resp_schema(schema, "BusinessConceptVersionResponse")
             |> json_response(:forbidden)
    end
  end

  describe "set business_concept_version confidential" do
    @tag authentication: [role: "admin"]
    @tag :template
    test "updates business concept confidential and renders version", %{
      conn: conn,
      swagger_schema: schema
    } do
      %{user_id: user_id} = build(:claims)

      business_concept_version = insert(:business_concept_version, last_change_by: user_id)
      business_concept_version_id = business_concept_version.id
      business_concept_id = business_concept_version.business_concept_id

      assert %{"data" => data} =
               conn
               |> post(
                 Routes.business_concept_version_business_concept_version_path(
                   conn,
                   :set_confidential,
                   business_concept_version
                 ),
                 confidential: true
               )
               |> validate_resp_schema(schema, "BusinessConceptVersionResponse")
               |> json_response(:ok)

      assert %{"id" => ^business_concept_version_id} = data

      assert %{"data" => data} =
               conn
               |> get(
                 Routes.business_concept_business_concept_version_path(
                   conn,
                   :show,
                   business_concept_id,
                   business_concept_version_id
                 )
               )
               |> validate_resp_schema(schema, "BusinessConceptVersionResponse")
               |> json_response(:ok)

      assert %{"confidential" => true} = data
    end

    @tag authentication: [role: "admin"]
    @tag :template
    test "renders error if invalid value for confidential", %{conn: conn} do
      business_concept_version = insert(:business_concept_version)

      assert %{"errors" => errors} =
               conn
               |> post(
                 Routes.business_concept_version_business_concept_version_path(
                   conn,
                   :set_confidential,
                   business_concept_version
                 ),
                 confidential: "SI"
               )
               |> json_response(:unprocessable_entity)

      assert %{"business_concept" => %{"confidential" => ["is invalid"]}} == errors
    end
  end

  describe "bulk_update" do
    @tag authentication: [role: "admin"]
    @tag template: [
           %{
             "name" => "group",
             "fields" => [
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
             ]
           }
         ]
    test "bulk update of business concept", %{conn: conn} do
      domain = insert(:domain, name: "domain1")
      domain_new = insert(:domain, name: "domain_new")
      business_concept = insert(:business_concept, domain: domain, type: @template_name)

      insert(
        :business_concept_version,
        business_concept: business_concept,
        name: "version_draft",
        status: "draft"
      )

      version_published =
        insert(
          :business_concept_version,
          business_concept: business_concept,
          name: "version_published",
          status: "published"
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

    @tag authentication: [role: "admin"]
    @tag template: [
           %{
             "name" => "group",
             "fields" => [
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
             ]
           }
         ]
    test "bulk update of business concept with no domain", %{conn: conn} do
      domain = insert(:domain, name: "domain1")
      business_concept = insert(:business_concept, domain: domain, type: @template_name)

      insert(
        :business_concept_version,
        business_concept: business_concept,
        name: "version_draft",
        status: "draft"
      )

      insert(
        :business_concept_version,
        business_concept: business_concept,
        name: "version_published",
        status: "published"
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
end
