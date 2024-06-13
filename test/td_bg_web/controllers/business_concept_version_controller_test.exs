defmodule TdBgWeb.BusinessConceptVersionControllerTest do
  use TdBgWeb.ConnCase
  use PhoenixSwagger.SchemaTest, "priv/static/swagger.json"

  import Mox

  alias TdBg.I18nContents.I18nContents
  alias TdCache.I18nCache

  alias TdCore.Search.IndexWorker

  @template_name "some_type"
  @content [
    %{
      "name" => "group",
      "fields" => [
        %{"name" => "Field1", "type" => "string", "cardinality" => "?"},
        %{"name" => "Field2", "type" => "string", "cardinality" => "?"}
      ]
    }
  ]

  @completeness_content [
    %{
      "name" => "Basic",
      "fields" => [
        %{
          "name" => "df_description",
          "type" => "enriched_text",
          "label" => "Descripción",
          "values" => nil,
          "widget" => "enriched_text",
          "cardinality" => "?"
        },
        %{
          "name" => "basic_list",
          "type" => "string",
          "label" => "Basic List",
          "values" => %{"fixed" => ["1", "2", "3", "4"]},
          "widget" => "dropdown",
          "cardinality" => "1"
        },
        %{
          "name" => "basic_switch",
          "type" => "string",
          "label" => "Basic Switch",
          "values" => %{
            "switch" => %{
              "on" => "basic_list",
              "values" => %{
                "1" => ["a", "b"],
                "2" => ["c", "d"]
              }
            }
          },
          "widget" => "dropdown",
          "cardinality" => "?"
        },
        %{
          "name" => "default_dependency",
          "type" => "string",
          "label" => "Dependent field with default values",
          "values" => %{
            "switch" => %{
              "on" => "basic_list",
              "values" => %{
                "1" => ["1.1", "1..2", "1.3", "1.4", "1.5"],
                "2" => ["2.1", "2.2", "2.3"],
                "3" => ["3.1", "3.2", "3.3", "3.4", "3.5"]
              }
            }
          },
          "widget" => "dropdown",
          "default" => %{"1" => "1.1", "2" => "2.2", "3" => "3.4"},
          "cardinality" => "?"
        },
        %{
          "name" => "Identificador",
          "type" => "string",
          "label" => "Identificador",
          "values" => nil,
          "widget" => "identifier",
          "cardinality" => "0"
        },
        %{
          "name" => "multiple_values",
          "type" => "string",
          "label" => "Multiple values",
          "values" => %{"fixed" => ["v-1", "v-2", "v-3"]},
          "widget" => "checkbox",
          "cardinality" => "*"
        },
        %{
          "name" => "user1",
          "type" => "user",
          "label" => "User 1",
          "values" => %{"role_users" => "Data Owner", "processed_users" => []},
          "widget" => "dropdown",
          "cardinality" => "?"
        },
        %{
          "name" => "User Group",
          "type" => "user_group",
          "label" => "User Group",
          "values" => %{
            "role_groups" => "Data Owner",
            "processed_users" => [],
            "processed_groups" => []
          },
          "widget" => "dropdown",
          "cardinality" => "?"
        },
        %{
          "name" => "text_area",
          "type" => "string",
          "label" => "Text area",
          "values" => nil,
          "widget" => "string",
          "cardinality" => "?"
        },
        %{
          "name" => "enriched_text",
          "type" => "enriched_text",
          "label" => "Enriched text",
          "values" => nil,
          "widget" => "enriched_text",
          "cardinality" => "?"
        },
        %{
          "name" => "text_input",
          "type" => "string",
          "label" => "Text input",
          "values" => nil,
          "widget" => "string",
          "cardinality" => "1"
        },
        %{
          "name" => "empty test",
          "type" => "string",
          "label" => "empty test",
          "values" => %{"fixed" => ["a", "s", "d"]},
          "widget" => "dropdown",
          "cardinality" => "?"
        },
        %{
          "name" => "Hierarchie2",
          "type" => "hierarchy",
          "label" => "Hierarchie",
          "values" => %{"hierarchy" => %{"id" => 4, "min_depth" => "2"}},
          "widget" => "dropdown",
          "cardinality" => "?"
        }
      ]
    }
  ]

  setup_all do
    start_supervised!(TdBg.Cache.ConceptLoader)
    :ok
  end

  setup _context do
    on_exit(fn ->
      IndexWorker.clear()
      TdCache.Redix.del!("i18n:locales:*")
    end)

    :ok
  end

  setup :set_mox_from_context
  setup :verify_on_exit!

  setup context do
    case context[:template] do
      nil ->
        :ok

      true ->
        %{id: template_id} =
          Templates.create_template(%{
            id: 0,
            name: @template_name,
            label: "label",
            scope: "test",
            content: @content
          })

        on_exit(fn ->
          Templates.delete(template_id)
        end)

      content ->
        %{id: template_id} =
          Templates.create_template(%{
            id: 0,
            name: @template_name,
            label: "label",
            scope: "test",
            content: content
          })

        on_exit(fn ->
          Templates.delete(template_id)
        end)
    end

    :ok
  end

  describe "GET /api/business_concepts/:business_concept_id/versions/:id" do
    @tag authentication: [role: "admin"]
    test "shows the specified business_concept_version including it's name, domain and content",
         %{conn: conn} do
      business_concept_version =
        insert(
          :business_concept_version,
          content: %{"foo" => "bar"},
          name: "Concept Name"
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
    test "shows the specified business_concept_version with i18n_content",
         %{conn: conn} do
      %{id: bcv_id, business_concept: %{id: bc_id}} =
        insert(
          :business_concept_version,
          content: %{"foo" => "bar"},
          name: "Concept Name",
          type: @template_name
        )

      %{lang: lang, name: name, content: content} =
        insert(:i18n_content, business_concept_version_id: bcv_id)

      assert %{"data" => %{"i18n_content" => i18n_content}} =
               conn
               |> get(
                 Routes.business_concept_business_concept_version_path(
                   conn,
                   :show,
                   bc_id,
                   "current"
                 )
               )
               |> json_response(:ok)

      assert %{
               ^lang => %{
                 "name" => ^name,
                 "content" => ^content
               }
             } = i18n_content

      assert %{"data" => %{"i18n_content" => i18n_content}} =
               conn
               |> get(
                 Routes.business_concept_business_concept_version_path(
                   conn,
                   :show,
                   bc_id,
                   bcv_id
                 )
               )
               |> json_response(:ok)

      assert %{
               ^lang => %{
                 "name" => ^name,
                 "content" => ^content
               }
             } = i18n_content
    end

    @tag authentication: [role: "admin"]
    @tag template: @completeness_content
    test "shows the completeness for i18n_content ",
         %{conn: conn} do
      no_text_content = %{"basic_list" => "1"}

      busines_concept_content =
        %{
          "df_description" => %{
            "document" => %{
              "nodes" => [
                %{
                  "nodes" => [
                    %{
                      "marks" => [],
                      "object" => "text",
                      "text" => "enrich text"
                    }
                  ],
                  "object" => "block",
                  "type" => "paragraph"
                }
              ]
            }
          }
        }
        |> Map.merge(no_text_content)

      %{id: bcv_id, business_concept: %{id: bc_id}} =
        insert(
          :business_concept_version,
          content: busines_concept_content,
          name: "Concept Name",
          type: @template_name
        )

      i18n_content = %{"text_input" => "foo", "text_area" => "bar"}

      %{lang: lang} =
        insert(:i18n_content,
          business_concept_version_id: bcv_id,
          content: i18n_content
        )

      assert %{
               "data" => %{
                 "completeness" => bc_completeness,
                 "i18n_content" => i18n_content
               }
             } =
               conn
               |> get(
                 Routes.business_concept_business_concept_version_path(
                   conn,
                   :show,
                   bc_id,
                   "current"
                 )
               )
               |> json_response(:ok)

      assert bc_completeness == 15.38

      assert %{^lang => %{"content" => i18n_content, "completeness" => i18n_completeness}} =
               i18n_content

      assert i18n_completeness == 23.08

      assert %{
               "basic_list" => "1",
               "text_area" => "bar",
               "text_input" => "foo"
             } == Map.merge(i18n_content, no_text_content)
    end

    @tag authentication: [role: "admin"]
    test "shows the domains in which it has been shared", %{conn: conn} do
      %{id: domain_id1} = CacheHelpers.insert_domain()
      %{id: domain_id2} = CacheHelpers.insert_domain()

      %{business_concept_id: id} = insert(:business_concept_version)

      insert(:shared_concept, business_concept_id: id, domain_id: domain_id1)
      insert(:shared_concept, business_concept_id: id, domain_id: domain_id2)

      link = "/api/business_concepts/#{id}/shared_domains"

      assert %{"data" => data} =
               conn
               |> get(
                 Routes.business_concept_business_concept_version_path(
                   conn,
                   :show,
                   id,
                   "current"
                 )
               )
               |> json_response(:ok)

      assert %{"_embedded" => embedded, "actions" => actions} = data
      assert %{"shared_to" => [%{"id" => ^domain_id1}, %{"id" => ^domain_id2}]} = embedded
      assert %{"share" => share} = actions
      assert %{"href" => ^link, "method" => "PATCH", "input" => %{}} = share
    end

    @tag authentication: [user_name: "not_an_admin"]
    test "show with actions", %{conn: conn, claims: claims} do
      %{id: domain_id} = CacheHelpers.insert_domain()

      put_session_permissions(claims, domain_id, [
        :manage_business_concept_links,
        :view_draft_business_concepts
      ])

      %{id: id, business_concept_id: business_concept_id} =
        insert(:business_concept_version,
          business_concept: build(:business_concept, domain_id: domain_id)
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

      assert %{"create_concept_link" => _, "create_structure_link" => _} = actions
    end

    @tag authentication: [
           user_name: "not_an_admin",
           permissions: ["manage_business_concepts_domain", "view_draft_business_concepts"]
         ]
    @tag :template
    test "user with manage_business_concepts_domain permission has update_domain action", %{
      conn: conn,
      domain_id: domain_id
    } do
      %{id: id, business_concept_id: business_concept_id} =
        insert(:business_concept_version, domain_id: domain_id)

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

    @tag authentication: [
           role: "user",
           permissions: [
             "view_approval_pending_business_concepts",
             "view_deprecated_business_concepts",
             "view_draft_business_concepts",
             "publish_business_concept",
             "reject_business_concept"
           ]
         ]
    @tag :template
    test "user with publish_business_concepts permission has publish actions", %{
      conn: conn,
      domain_id: domain_id
    } do
      [pending_actions, draft_actions, deprecated_actions] =
        ["pending_approval", "draft", "deprecated"]
        |> Enum.map(&insert(:business_concept_version, domain_id: domain_id, status: &1))
        |> Enum.map(fn %{id: id, business_concept_id: business_concept_id} ->
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
          |> Map.get("_actions")
        end)

      assert [true, false, false] =
               Enum.map(
                 [
                   pending_actions,
                   draft_actions,
                   deprecated_actions
                 ],
                 &Map.has_key?(&1, "publish")
               )

      assert [false, false, true] =
               Enum.map(
                 [
                   pending_actions,
                   draft_actions,
                   deprecated_actions
                 ],
                 &Map.has_key?(&1, "restore")
               )

      assert [true, false, false] =
               Enum.map(
                 [
                   pending_actions,
                   draft_actions,
                   deprecated_actions
                 ],
                 &Map.has_key?(&1, "reject")
               )
    end

    @tag authentication: [role: "admin"]
    @tag :template
    test "admin has update_domain action", %{conn: conn} do
      %{id: domain_id} = CacheHelpers.insert_domain()

      %{id: id, business_concept_id: business_concept_id} =
        insert(:business_concept_version, domain_id: domain_id)

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

    @tag authentication: [user_name: "not_an_admin"]
    test "includes share action if non-admin user has :share_with_domain permission",
         %{conn: conn, claims: claims} do
      %{id: domain_id} = CacheHelpers.insert_domain()

      put_session_permissions(claims, domain_id, [
        :update_business_concept,
        :view_draft_business_concepts,
        :share_with_domain
      ])

      %{id: id, business_concept_id: business_concept_id} =
        insert(:business_concept_version,
          business_concept: build(:business_concept, domain_id: domain_id)
        )

      link = "/api/business_concepts/#{business_concept_id}/shared_domains"

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
               |> json_response(:ok)

      assert %{"actions" => actions} = data
      assert %{"share" => share} = actions
      assert %{"href" => ^link, "method" => "PATCH", "input" => %{}} = share
    end

    @tag authentication: [user_name: "not_an_admin"]
    test "includes create_implementation action if non-admin user has permissions to create ruleless implementation",
         %{conn: conn, claims: claims} do
      %{id: domain_id} = CacheHelpers.insert_domain()

      put_session_permissions(claims, domain_id, [
        :update_business_concept,
        :view_draft_business_concepts,
        :manage_ruleless_implementations,
        :manage_quality_rule_implementations
      ])

      %{id: id, business_concept_id: business_concept_id} =
        insert(:business_concept_version,
          business_concept: build(:business_concept, domain_id: domain_id)
        )

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
               |> json_response(:ok)

      assert %{"actions" => actions} = data
      assert Map.get(actions, "create_implementation") == %{"method" => "POST"}
    end

    @tag authentication: [user_name: "not_an_admin"]
    test "includes create_raw_implementation action if non-admin user has permissions to create raw ruleless implementation",
         %{conn: conn, claims: claims} do
      %{id: domain_id} = CacheHelpers.insert_domain()

      put_session_permissions(claims, domain_id, [
        :update_business_concept,
        :view_draft_business_concepts,
        :manage_raw_quality_rule_implementations,
        :manage_ruleless_implementations
      ])

      %{id: id, business_concept_id: business_concept_id} =
        insert(:business_concept_version,
          business_concept: build(:business_concept, domain_id: domain_id)
        )

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
               |> json_response(:ok)

      assert %{"actions" => actions} = data
      assert Map.get(actions, "create_raw_implementation") == %{"method" => "POST"}
    end

    @tag authentication: [user_name: "not_an_admin"]
    test "includes create_link_implementation action if non-admin user has permissions to create links to implementations",
         %{conn: conn, claims: claims} do
      %{id: domain_id} = CacheHelpers.insert_domain()

      put_session_permissions(claims, domain_id, [
        :update_business_concept,
        :view_draft_business_concepts,
        :link_implementation_business_concept
      ])

      %{id: id, business_concept_id: business_concept_id} =
        insert(:business_concept_version,
          business_concept: build(:business_concept, domain_id: domain_id)
        )

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
               |> json_response(:ok)

      assert %{"actions" => actions} = data
      assert Map.get(actions, "create_link_implementation") == %{"method" => "POST"}
    end

    @tag authentication: [
           user_name: "not_an_admin",
           permissions: [:update_business_concept, :view_draft_business_concepts]
         ]
    test "returns false as the value of share action if user does not have :share_with_domain permission",
         %{conn: conn, domain_id: domain_id} do
      %{id: id, business_concept_id: business_concept_id} =
        insert(:business_concept_version, domain_id: domain_id)

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
               |> json_response(:ok)

      assert %{"actions" => actions} = data
      assert Map.get(actions, "share") == false
    end

    @tag authentication: [
           user_name: "not_an_admin",
           permissions: [:update_business_concept, :view_draft_business_concepts]
         ]
    test "no returns action for implementations if user does not have permissions",
         %{conn: conn, domain_id: domain_id} do
      %{id: id, business_concept_id: business_concept_id} =
        insert(:business_concept_version, domain_id: domain_id)

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
               |> json_response(:ok)

      assert %{"actions" => actions} = data
      refute Map.has_key?(actions, "create_implementation")
      refute Map.has_key?(actions, "create_raw_implementation")
      refute Map.has_key?(actions, "create_link_implementation")
    end

    @tag authentication: [user_name: "not_an_admin"]
    test "show actions in shared domains", %{conn: conn, claims: claims} do
      %{id: shared_id} = shared = CacheHelpers.insert_domain()
      %{id: domain_id} = CacheHelpers.insert_domain()

      put_session_permissions(claims, %{
        "view_draft_business_concepts" => [shared_id],
        "manage_business_concept_links" => [shared_id]
      })

      %{id: id, business_concept_id: business_concept_id} =
        insert(:business_concept_version,
          business_concept: build(:business_concept, domain_id: domain_id, shared_to: [shared])
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

    @tag authentication: [user_name: "not_an_admin"]
    test "shows concept when we have permissions over shared domain", %{
      conn: conn,
      claims: claims
    } do
      %{id: shared_id} = shared = CacheHelpers.insert_domain()
      %{id: domain_id} = CacheHelpers.insert_domain()
      put_session_permissions(claims, %{"view_draft_business_concepts" => [shared_id]})

      %{id: id, business_concept_id: business_concept_id} =
        insert(:business_concept_version,
          business_concept: build(:business_concept, domain_id: domain_id, shared_to: [shared])
        )

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
               |> json_response(:ok)

      assert %{
               "id" => ^id,
               "business_concept_id" => ^business_concept_id,
               "_embedded" => %{
                 "shared_to" => [%{"id" => ^shared_id}]
               }
             } = data
    end

    @tag authentication: [user_name: "not_an_admin"]
    test "show only links with correct permissions", %{conn: conn, claims: claims} do
      %{id: domain_id} = CacheHelpers.insert_domain()
      %{id: domain_id_without_permission} = CacheHelpers.insert_domain()

      put_session_permissions(claims, %{
        "view_quality_rule" => [domain_id],
        "view_data_structure" => [domain_id],
        "view_draft_business_concepts" => [domain_id]
      })

      %{id: id, business_concept_id: business_concept_id} =
        insert(:business_concept_version,
          business_concept: build(:business_concept, domain_id: domain_id)
        )

      %{id: data_structure_id} = CacheHelpers.insert_data_structure(%{domain_ids: [domain_id]})
      %{id: implementation_id} = CacheHelpers.insert_implementation(%{domain_id: domain_id})

      %{id: data_structure_id_without_permission} =
        CacheHelpers.insert_data_structure(%{domain_ids: [domain_id_without_permission]})

      %{id: implementation_id_without_permission} =
        CacheHelpers.insert_implementation(%{domain_id: domain_id_without_permission})

      CacheHelpers.insert_link(
        business_concept_id,
        "business_concept",
        "data_structure",
        data_structure_id
      )

      CacheHelpers.insert_link(
        business_concept_id,
        "business_concept",
        "data_structure",
        data_structure_id_without_permission
      )

      CacheHelpers.insert_link(
        implementation_id,
        "implementation_ref",
        "business_concept",
        business_concept_id
      )

      CacheHelpers.insert_link(
        implementation_id_without_permission,
        "implementation_ref",
        "business_concept",
        business_concept_id
      )

      string_data_structure_id = Integer.to_string(data_structure_id)

      assert %{
               "data" => %{
                 "id" => ^id,
                 "business_concept_id" => ^business_concept_id,
                 "_embedded" => %{
                   "links" => links
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

      assert Enum.count(links) == 2

      assert string_data_structure_id ==
               links
               |> Enum.find(fn %{"resource_type" => resource_type} ->
                 resource_type == "data_structure"
               end)
               |> Map.get("resource_id")

      assert implementation_id ==
               links
               |> Enum.find(fn %{"resource_type" => resource_type} ->
                 resource_type == "implementation"
               end)
               |> Map.get("resource_id")
    end

    @tag authentication: [user_name: "not_an_admin"]
    test "render correct delete permissions for implementation links", %{
      conn: conn,
      claims: claims
    } do
      %{id: manage_perm_domain_id} = CacheHelpers.insert_domain()
      %{id: view_perm_domain_id} = CacheHelpers.insert_domain()

      put_session_permissions(claims, %{
        "view_quality_rule" => [view_perm_domain_id, manage_perm_domain_id],
        "view_data_structure" => [view_perm_domain_id, manage_perm_domain_id],
        "view_draft_business_concepts" => [view_perm_domain_id, manage_perm_domain_id],
        "link_implementation_business_concept" => [manage_perm_domain_id]
      })

      %{id: id, business_concept_id: business_concept_id} =
        insert(:business_concept_version,
          business_concept: build(:business_concept, domain_id: view_perm_domain_id)
        )

      %{id: manage_perm_implementation_id} =
        CacheHelpers.insert_implementation(%{domain_id: manage_perm_domain_id})

      %{id: view_perm_implementation_id} =
        CacheHelpers.insert_implementation(%{domain_id: view_perm_domain_id})

      CacheHelpers.insert_link(
        manage_perm_implementation_id,
        "implementation_ref",
        "business_concept",
        business_concept_id
      )

      CacheHelpers.insert_link(
        view_perm_implementation_id,
        "implementation_ref",
        "business_concept",
        business_concept_id
      )

      assert %{
               "data" => %{
                 "id" => ^id,
                 "business_concept_id" => ^business_concept_id,
                 "_embedded" => %{
                   "links" => links
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

      assert Enum.count(links) == 2

      assert links
             |> Enum.find(fn %{"resource_id" => resource_id} ->
               resource_id == manage_perm_implementation_id
             end)
             |> Map.get("_actions")
             |> Map.has_key?("delete")

      refute links
             |> Enum.find(fn %{"resource_id" => resource_id} ->
               resource_id == view_perm_implementation_id
             end)
             |> Map.get("_actions")
             |> Map.has_key?("delete")
    end
  end

  describe "GET /api/business_concept_versions" do
    for role <- ["admin", "service"] do
      @tag authentication: [role: "admin"]
      test "#{role} account can list all business_concept_versions", %{conn: conn} do
        %{id: id} = bcv = insert(:business_concept_version)

        expect(ElasticsearchMock, :request, fn
          _,
          :post,
          "/concepts/_search",
          %{from: 0, query: query, size: 50, sort: ["_score", "name.raw"]},
          _ ->
            assert query == %{bool: %{filter: %{match_all: %{}}}}
            SearchHelpers.hits_response([bcv])
        end)

        assert %{"data" => [%{"id" => ^id}]} =
                 conn
                 |> get(Routes.business_concept_version_path(conn, :index))
                 |> json_response(:ok)
      end
    end
  end

  describe "POST /api/business_concept_versions/search" do
    @tag authentication: [user_name: "not_an_admin"]
    test "user search with filters", %{conn: conn} do
      %{id: parent_id, external_id: parent_external_id, name: parent_name} =
        CacheHelpers.insert_domain()

      %{id: domain_id, external_id: domain_external_id, name: domain_name} =
        CacheHelpers.insert_domain(parent_id: parent_id)

      CacheHelpers.put_default_permissions(["view_published_business_concepts"])

      %{id: id} = bcv = insert(:business_concept_version, domain_id: domain_id)

      expect(
        ElasticsearchMock,
        :request,
        fn _,
           :post,
           "/concepts/_search",
           %{from: 0, query: %{bool: bool}, size: 50, sort: ["_score", "name.raw"]},
           _ ->
          assert %{
                   filter: [_status_filter, _confidential_filter, %{term: %{"domain_id" => 1234}}],
                   must: %{simple_query_string: %{query: "foo*"}}
                 } = bool

          SearchHelpers.hits_response([bcv])
        end
      )

      params = %{filters: %{"domain_id" => [1234]}, query: "foo"}

      assert %{"data" => [%{"id" => ^id, "domain_parents" => domain_parents}]} =
               conn
               |> post(Routes.business_concept_version_path(conn, :search), params)
               |> json_response(:ok)

      assert domain_parents == [
               %{"id" => domain_id, "external_id" => domain_external_id, "name" => domain_name},
               %{"id" => parent_id, "external_id" => parent_external_id, "name" => parent_name}
             ]
    end

    for role <- ["admin", "service"] do
      @tag authentication: [role: role]
      test "#{role} account filter by status", %{conn: conn} do
        %{id: id} = bcv = insert(:business_concept_version)

        expect(
          ElasticsearchMock,
          :request,
          fn _,
             :post,
             "/concepts/_search",
             %{from: 0, query: query, size: 50, sort: ["_score", "name.raw"]},
             _ ->
            assert query == %{bool: %{filter: %{terms: %{"status" => ["published", "rejected"]}}}}
            SearchHelpers.hits_response([bcv])
          end
        )

        params = %{filters: %{"status" => ["published", "rejected"]}}

        assert %{"data" => [%{"id" => ^id}]} =
                 conn
                 |> post(Routes.business_concept_version_path(conn, :search), params)
                 |> json_response(:ok)
      end
    end

    @tag authentication: [user_name: "not_an_admin", permissions: ["publish_business_concept"]]
    test "actions for non admin user", %{
      conn: conn
    } do
      expect(
        ElasticsearchMock,
        :request,
        fn _,
           :post,
           "/concepts/_search",
           %{from: 0, query: _, size: 50, sort: ["_score", "name.raw"]},
           _ ->
          SearchHelpers.hits_response([])
        end
      )

      assert %{"_actions" => actions} =
               conn
               |> post(Routes.business_concept_version_path(conn, :search), only_linkable: true)
               |> json_response(:ok)

      assert %{
               "autoPublish" => %{
                 "href" => "/api/business_concept_versions/upload",
                 "input" => %{},
                 "method" => "POST"
               }
             } = actions
    end

    @tag authentication: [role: "admin"]
    test "actions for admin user", %{
      conn: conn
    } do
      expect(
        ElasticsearchMock,
        :request,
        fn _,
           :post,
           "/concepts/_search",
           %{from: 0, query: _, size: 50, sort: ["_score", "name.raw"]},
           _ ->
          SearchHelpers.hits_response([])
        end
      )

      assert %{"_actions" => actions} =
               conn
               |> post(Routes.business_concept_version_path(conn, :search), only_linkable: true)
               |> json_response(:ok)

      assert %{
               "autoPublish" => %{},
               "create" => %{},
               "upload" => %{}
             } = actions
    end

    @tag authentication: [user_name: "not_an_admin"]
    test "find only linkable concepts", %{conn: conn, claims: claims} do
      %{id: domain_id1} = CacheHelpers.insert_domain()
      %{id: domain_id2} = CacheHelpers.insert_domain()
      %{id: id} = bcv = insert(:business_concept_version)

      expect(ElasticsearchMock, :request, fn
        _, :post, "/concepts/_search", %{query: query}, _ ->
          assert %{bool: %{filter: [_, _, %{term: %{"domain_ids" => ^domain_id2}}]}} = query
          SearchHelpers.hits_response([bcv])
      end)

      put_session_permissions(claims, %{
        "view_draft_business_concepts" => [domain_id1, domain_id2],
        "manage_business_concept_links" => [domain_id2]
      })

      assert %{"data" => data} =
               conn
               |> post(Routes.business_concept_version_path(conn, :search), only_linkable: true)
               |> json_response(:ok)

      assert [%{"id" => ^id}] = data
    end
  end

  describe "POST /api/business_concept_versions/search with must params" do
    @tag authentication: [user_name: "not_an_admin"]
    test "user search with filters", %{conn: conn} do
      %{id: parent_id, external_id: parent_external_id, name: parent_name} =
        CacheHelpers.insert_domain()

      %{id: domain_id, external_id: domain_external_id, name: domain_name} =
        CacheHelpers.insert_domain(parent_id: parent_id)

      CacheHelpers.put_default_permissions(["view_published_business_concepts"])

      %{id: id} = bcv = insert(:business_concept_version, domain_id: domain_id)

      expect(
        ElasticsearchMock,
        :request,
        fn _,
           :post,
           "/concepts/_search",
           %{from: 0, query: %{bool: bool}, size: 50, sort: ["_score", "name.raw"]},
           _ ->
          assert %{
                   must: [
                     %{simple_query_string: %{query: "foo*"}},
                     _status_filter,
                     _confidential_filter,
                     %{term: %{"domain_id" => 1234}}
                   ],
                   should: %{multi_match: %{operator: "and", query: "foo*", type: "best_fields"}}
                 } = bool

          SearchHelpers.hits_response([bcv])
        end
      )

      params = %{must: %{"domain_id" => [1234]}, query: "foo"}

      assert %{"data" => [%{"id" => ^id, "domain_parents" => domain_parents}]} =
               conn
               |> post(Routes.business_concept_version_path(conn, :search), params)
               |> json_response(:ok)

      assert domain_parents == [
               %{"id" => domain_id, "external_id" => domain_external_id, "name" => domain_name},
               %{"id" => parent_id, "external_id" => parent_external_id, "name" => parent_name}
             ]
    end

    for role <- ["admin", "service"] do
      @tag authentication: [role: role]
      test "#{role} account filter by status", %{conn: conn} do
        %{id: id} = bcv = insert(:business_concept_version)

        expect(
          ElasticsearchMock,
          :request,
          fn _,
             :post,
             "/concepts/_search",
             %{from: 0, query: query, size: 50, sort: ["_score", "name.raw"]},
             _ ->
            assert query == %{bool: %{must: %{terms: %{"status" => ["published", "rejected"]}}}}
            SearchHelpers.hits_response([bcv])
          end
        )

        params = %{must: %{"status" => ["published", "rejected"]}}

        assert %{"data" => [%{"id" => ^id}]} =
                 conn
                 |> post(Routes.business_concept_version_path(conn, :search), params)
                 |> json_response(:ok)
      end
    end
  end

  describe "create business_concept" do
    setup :set_mox_from_context

    @tag authentication: [role: "user"]
    @tag :template
    test "renders business_concept when data is valid", %{
      conn: conn,
      claims: claims,
      swagger_schema: schema
    } do
      %{id: domain_id, name: domain_name} = CacheHelpers.insert_domain()

      put_session_permissions(claims, domain_id, [
        :create_business_concept,
        :view_draft_business_concepts
      ])

      creation_attrs = %{
        "content" => %{},
        "type" => "some_type",
        "name" => "Some name",
        "domain_id" => domain_id,
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

      assert data["domain"]["id"] == domain_id
      assert data["domain"]["name"] == domain_name
      assert [{:reindex, :concepts, [_]}] = IndexWorker.calls()
    end

    @tag authentication: [
           role: "user",
           permissions: [:create_business_concept, :view_draft_business_concepts]
         ]
    @tag template: @completeness_content
    test "insert i18n_content when data has i18n valid content", %{
      conn: conn,
      swagger_schema: schema,
      domain: %{id: domain_id}
    } do
      lang = "es"
      I18nCache.put_required_locales([lang])

      es_name = "es_nombre"
      es_content = %{"text_input" => "text_field1"}

      creation_attrs = %{
        "content" => %{"basic_list" => "1", "text_input" => "bc text"},
        "i18n_content" => %{
          lang => %{"name" => es_name, "content" => es_content}
        },
        "type" => @template_name,
        "name" => "Some name",
        "domain_id" => domain_id
      }

      assert %{"data" => data} =
               conn
               |> post(
                 Routes.business_concept_version_path(conn, :create),
                 business_concept_version: creation_attrs
               )
               |> validate_resp_schema(schema, "BusinessConceptVersionResponse")
               |> json_response(:created)

      assert %{"i18n_content" => i18n_content} = data

      assert %{
               ^lang => %{
                 "name" => ^es_name,
                 "content" => ^es_content
               }
             } = i18n_content
    end

    @tag authentication: [role: "user"]
    test "doesn't allow concept creation when not in domain", %{
      conn: conn,
      swagger_schema: schema
    } do
      domain = insert(:domain)

      creation_attrs = %{
        "content" => %{},
        "type" => "some_type",
        "name" => "Some name",
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
    @tag :template
    test "renders errors when data is invalid", %{conn: conn, swagger_schema: schema} do
      domain = insert(:domain)

      creation_attrs = %{
        content: %{},
        type: @template_name,
        name: nil,
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

    @tag authentication: [
           role: "user",
           permissions: [:create_business_concept, :view_draft_business_concepts]
         ]
    @tag template: @completeness_content
    test "renders errors when  data has i18n invalid content", %{
      conn: conn,
      swagger_schema: schema,
      domain: %{id: domain_id}
    } do
      lang = "es"
      es_name = "es_nombre"
      es_content = %{"text_area" => "text_field1"}

      I18nCache.put_required_locales([lang])

      creation_attrs = %{
        "content" => %{"basic_list" => "1", "text_input" => "bc text"},
        "i18n_content" => %{
          lang => %{"name" => es_name, "content" => es_content}
        },
        "type" => @template_name,
        "name" => "Some name",
        "domain_id" => domain_id
      }

      assert %{"errors" => errors} =
               conn
               |> post(
                 Routes.business_concept_version_path(conn, :create),
                 business_concept_version: creation_attrs
               )
               |> validate_resp_schema(schema, "BusinessConceptVersionResponse")
               |> json_response(422)

      assert [
               %{
                 "code" => "undefined",
                 "name" => "concept.error.text_input.language.es: can't be blank"
               }
             ] == errors
    end
  end

  describe "index_by_name" do
    @tag authentication: [role: "admin"]
    test "search business concept prefix query", %{conn: conn} do
      %{id: id} = bcv = insert(:business_concept_version)

      ElasticsearchMock
      |> expect(:request, fn
        _,
        :post,
        "/concepts/_search",
        %{from: 0, query: query, size: 50, sort: ["_score", "name.raw"]},
        _ ->
          assert query == %{
                   bool: %{
                     filter: %{match_all: %{}},
                     must: %{simple_query_string: %{query: "foo*"}}
                   }
                 }

          SearchHelpers.hits_response([bcv])
      end)

      assert %{"data" => data} =
               conn
               |> get(Routes.business_concept_version_path(conn, :index), %{query: "foo"})
               |> json_response(:ok)

      assert [%{"id" => ^id}] = data
    end
  end

  describe "index by business concept id" do
    @tag authentication: [role: "admin"]
    test "lists business_concept_versions", %{conn: conn} do
      %{id: id, business_concept_id: business_concept_id} =
        bcv = insert(:business_concept_version)

      ElasticsearchMock
      |> expect(
        :request,
        fn _,
           :post,
           "/concepts/_search",
           %{from: 0, query: query, size: 50, sort: ["_score", "name.raw"]},
           _ ->
          assert query == %{
                   bool: %{filter: %{term: %{"business_concept_id" => business_concept_id}}}
                 }

          SearchHelpers.hits_response([bcv])
        end
      )

      assert %{"data" => data} =
               conn
               |> get(
                 Routes.business_concept_business_concept_version_path(
                   conn,
                   :index,
                   business_concept_id
                 )
               )
               |> json_response(:ok)

      assert [%{"id" => ^id}] = data
    end
  end

  describe "create new versions" do
    setup :set_mox_from_context

    @tag authentication: [role: "admin"]
    test "create new version with modified template", %{conn: conn} do
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
      assert [{:reindex, :concepts, [_]}] = IndexWorker.calls()
    end

    @tag authentication: [role: "admin"]
    test "create new version with i18n_content", %{
      conn: conn,
      claims: %{user_id: user_id}
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

      business_concept =
        insert(:business_concept,
          type: template.name,
          last_change_by: user_id
        )

      %{id: bcv_id} =
        insert(
          :business_concept_version,
          business_concept: business_concept,
          last_change_by: user_id,
          status: "published"
        )

      %{lang: lang, content: content, name: name} =
        insert(:i18n_content, business_concept_version_id: bcv_id)

      assert %{"data" => %{"id" => new_bcv_id, "i18n_content" => i18n_content}} =
               conn
               |> post(
                 Routes.business_concept_version_business_concept_version_path(
                   conn,
                   :version,
                   bcv_id
                 )
               )
               |> json_response(:created)

      assert [%{name: ^name, content: ^content}] =
               I18nContents.get_all_i18n_content_by_bcv_id(new_bcv_id)

      assert %{^lang => %{"name" => ^name, "content" => ^content}} = i18n_content
    end
  end

  describe "update business_concept_version" do
    setup :set_mox_from_context

    @tag authentication: [role: "admin"]
    @tag :template
    test "renders business_concept_version when data is valid", %{
      conn: conn,
      swagger_schema: schema
    } do
      %{id: id, business_concept_id: business_concept_id} =
        business_concept_version = insert(:business_concept_version, type: @template_name)

      update_attrs = %{
        "content" => %{"Field1" => "Foo", "Field2" => "bar"},
        "name" => "The new name"
      }

      assert %{"data" => data} =
               conn
               |> put(
                 Routes.business_concept_version_path(conn, :update, business_concept_version),
                 business_concept_version: update_attrs
               )
               |> validate_resp_schema(schema, "BusinessConceptVersionResponse")
               |> json_response(:ok)

      assert %{"id" => ^id} = data

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

      assert_maps_equal(data, update_attrs, ["content", "name"])
      assert [{:reindex, :concepts, [_]}] = IndexWorker.calls()
    end

    @tag authentication: [role: "admin"]
    @tag :template
    test "renders business_concept_version when with i18n_content", %{
      conn: conn,
      swagger_schema: schema
    } do
      %{id: id} =
        business_concept_version = insert(:business_concept_version, type: @template_name)

      %{lang: lang} = insert(:i18n_content, business_concept_version_id: id, content: %{})

      new_name = "The new name"
      new_content = %{"Field1" => "Foo", "Field2" => "bar"}

      update_attrs = %{
        "content" => new_content,
        "name" => new_name,
        "i18n_content" => %{lang => %{"content" => new_content, "name" => new_name}}
      }

      assert %{"data" => %{"i18n_content" => i18n_content}} =
               conn
               |> put(
                 Routes.business_concept_version_path(conn, :update, business_concept_version),
                 business_concept_version: update_attrs
               )
               |> validate_resp_schema(schema, "BusinessConceptVersionResponse")
               |> json_response(:ok)

      assert %{^lang => %{"name" => ^new_name, "content" => ^new_content}} = i18n_content
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
      assert [{:reindex, :concepts, [_]}] = IndexWorker.calls()
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

    @tag authentication: [role: "user"]
    @tag :template
    test "user with permission in new domain, can update business concept domain", %{
      conn: conn,
      claims: claims,
      swagger_schema: schema
    } do
      %{id: id1} = CacheHelpers.insert_domain()
      %{id: id2} = CacheHelpers.insert_domain()

      CacheHelpers.put_session_permissions(claims, %{
        "manage_business_concepts_domain" => [id1, id2],
        "update_business_concept" => [id1, id2]
      })

      business_concept_version = insert(:business_concept_version, domain_id: id1)

      assert %{"data" => data} =
               conn
               |> post(
                 Routes.business_concept_version_business_concept_version_path(
                   conn,
                   :update_domain,
                   business_concept_version
                 ),
                 domain_id: id2
               )
               |> validate_resp_schema(schema, "BusinessConceptVersionResponse")
               |> json_response(:ok)

      assert %{"domain" => %{"id" => ^id2}} = data
      assert [{:reindex, :concepts, [_]}] = IndexWorker.calls()
    end

    @tag authentication: [role: "admin"]
    @tag :template
    test "when restore a deprecated business concept version, will be surived in cache", %{
      conn: conn
    } do
      %{id: domain_id} = CacheHelpers.insert_domain()

      %{user_id: user_id} = build(:claims)

      %{id: bc_main_id} =
        business_concept =
        insert(:business_concept,
          last_change_by: user_id,
          domain_id: domain_id
        )

      %{id: bcv_main_id} =
        insert(:business_concept_version,
          business_concept: business_concept,
          status: "published"
        )

      conn
      |> post(
        Routes.business_concept_version_business_concept_version_path(
          conn,
          :deprecate,
          bcv_main_id
        )
      )
      |> json_response(:ok)

      assert {:ok, %{id: ^bc_main_id}} = CacheHelpers.get_business_concept(bc_main_id)
      assert [{:reindex, :concepts, [_]}] = IndexWorker.calls()
    end

    @tag authentication: [
           role: "user",
           permissions: [:publish_business_concept]
         ]

    test "when a business concept published is deprecated, related data is not deleted", %{
      conn: conn,
      domain: domain
    } do
      %{name: template_name} = CacheHelpers.insert_template()

      business_concept_version =
        insert(:business_concept_version,
          domain_id: domain.id,
          status: "deprecated",
          type: template_name
        )

      assert %{"data" => %{"status" => "published"}} =
               conn
               |> post(
                 Routes.business_concept_version_business_concept_version_path(
                   conn,
                   :restore,
                   business_concept_version
                 )
               )
               |> json_response(:ok)

      assert [{:reindex, :concepts, [_]}] = IndexWorker.calls()
    end

    @tag authentication: [
           role: "user",
           permissions: [:publish_business_concept]
         ]

    test "user with permission, can not restore a deprecated business concept domain when there is other with the same name, type and domain",
         %{
           conn: conn,
           domain: domain
         } do
      %{name: template_name} = CacheHelpers.insert_template()

      %{name: business_concept_name} =
        business_concept_version =
        insert(:business_concept_version,
          domain_id: domain.id,
          status: "deprecated",
          type: template_name
        )

      insert(:business_concept_version,
        name: business_concept_name,
        domain_id: domain.id,
        status: "draft",
        type: template_name
      )

      assert %{"errors" => [%{"name" => "concept.error.existing.business.concept"}]} =
               conn
               |> post(
                 Routes.business_concept_version_business_concept_version_path(
                   conn,
                   :restore,
                   business_concept_version
                 )
               )
               |> json_response(:unprocessable_entity)
    end

    @tag authentication: [
           role: "user",
           permissions: [:update_business_concept, :manage_business_concepts_domain]
         ]
    @tag :template
    test "user without permission in new domain, cannot update business concept domain", %{
      conn: conn,
      domain: domain,
      claims: claims,
      swagger_schema: schema
    } do
      business_concept_version =
        insert(:business_concept_version,
          business_concept: build(:business_concept, domain: domain)
        )

      %{id: domain_id} = insert(:domain)

      CacheHelpers.put_session_permissions(claims, domain_id, [:update_business_concept])

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
    setup :set_mox_from_context

    @tag authentication: [role: "admin"]
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
      assert [{:reindex, :concepts, [_]}] = IndexWorker.calls()
    end

    @tag authentication: [role: "admin"]
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
    setup :set_mox_from_context

    @tag authentication: [role: "admin"]
    test "bulk update of business concept", %{conn: conn} do
      %{id: domain_id} = CacheHelpers.insert_domain()
      %{name: template_name} = CacheHelpers.insert_template()
      %{id: id} = bcv = insert(:business_concept_version, type: template_name)

      ElasticsearchMock
      |> expect(:request, fn
        _,
        :post,
        "/concepts/_search",
        %{from: 0, query: query, size: 10_000, sort: ["_score", "name.raw"]},
        _ ->
          assert query == %{bool: %{filter: %{term: %{"status" => "published"}}}}
          SearchHelpers.hits_response([bcv])
      end)

      params = %{
        "update_attributes" => %{"domain_id" => domain_id},
        "search_params" => %{"filters" => %{"status" => ["published"]}}
      }

      assert %{"data" => data} =
               conn
               |> post(Routes.business_concept_version_path(conn, :bulk_update), params)
               |> json_response(:ok)

      assert %{"message" => updated_ids} = data
      assert updated_ids == [id]
      assert [{:reindex, :concepts, [_]}] = IndexWorker.calls()
    end

    @tag authentication: [role: "admin"]
    test "bulk update of business concept with invalid domain", %{conn: conn} do
      %{name: template_name} = CacheHelpers.insert_template()
      bcv = insert(:business_concept_version, type: template_name)

      ElasticsearchMock
      |> expect(:request, fn _, :post, "/concepts/_search", _, _ ->
        SearchHelpers.hits_response([bcv])
      end)

      params = %{
        "update_attributes" => %{"domain_id" => System.unique_integer([:positive])},
        "search_params" => %{"filters" => %{"status" => ["published"]}}
      }

      assert %{"error" => "missing_domain"} =
               conn
               |> post(Routes.business_concept_version_path(conn, :bulk_update), params)
               |> json_response(:unprocessable_entity)
    end

    @tag authentication: [role: "admin"]
    test "bulk update of business concept with must in params", %{conn: conn} do
      %{id: domain_id} = CacheHelpers.insert_domain()
      %{name: template_name} = CacheHelpers.insert_template()
      %{id: id} = bcv = insert(:business_concept_version, type: template_name)

      ElasticsearchMock
      |> expect(:request, fn
        _,
        :post,
        "/concepts/_search",
        %{from: 0, query: query, size: 10_000, sort: ["_score", "name.raw"]},
        _ ->
          assert query == %{bool: %{must: %{term: %{"status" => "published"}}}}
          SearchHelpers.hits_response([bcv])
      end)

      params = %{
        "update_attributes" => %{"domain_id" => domain_id},
        "search_params" => %{"must" => %{"status" => ["published"]}}
      }

      assert %{"data" => data} =
               conn
               |> post(Routes.business_concept_version_path(conn, :bulk_update), params)
               |> json_response(:ok)

      assert %{"message" => updated_ids} = data
      assert updated_ids == [id]
      assert [{:reindex, :concepts, [_]}] = IndexWorker.calls()
    end

    @tag authentication: [role: "admin"]
    test "bulk update of business concept with invalid domain wiht must in params", %{conn: conn} do
      %{name: template_name} = CacheHelpers.insert_template()
      bcv = insert(:business_concept_version, type: template_name)

      ElasticsearchMock
      |> expect(:request, fn _, :post, "/concepts/_search", _, _ ->
        SearchHelpers.hits_response([bcv])
      end)

      params = %{
        "update_attributes" => %{"domain_id" => System.unique_integer([:positive])},
        "search_params" => %{"must" => %{"status" => ["published"]}}
      }

      assert %{"error" => "missing_domain"} =
               conn
               |> post(Routes.business_concept_version_path(conn, :bulk_update), params)
               |> json_response(:unprocessable_entity)
    end
  end

  describe "get actions" do
    @tag authentication: [role: "admin"]
    test "actions for admin user", %{
      conn: conn
    } do
      assert %{"_actions" => actions} =
               conn
               |> get(Routes.business_concept_version_path(conn, :actions))
               |> json_response(:ok)

      assert %{
               "autoPublish" => %{},
               "create" => %{},
               "upload" => %{}
             } = actions
    end
  end
end
