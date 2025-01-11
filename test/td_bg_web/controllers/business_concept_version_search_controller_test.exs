defmodule TdBgWeb.BusinessConceptVersionSearchControllerTest do
  use TdBgWeb.ConnCase

  import ExUnit.CaptureLog
  import Mox

  alias TdCore.Search.IndexWorkerMock

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

  @complete_content [
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
          "default" => %{
            "value" => %{"1" => "1.1", "2" => "2.2", "3" => "3.4"},
            "origin" => "default"
          },
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
          "values" => "",
          "widget" => "string",
          "cardinality" => "?"
        },
        %{
          "name" => "enriched_text",
          "type" => "enriched_text",
          "label" => "Enriched text",
          "values" => "",
          "widget" => "enriched_text",
          "cardinality" => "?"
        },
        %{
          "name" => "text_input",
          "type" => "string",
          "label" => "Text input",
          "values" => "",
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
      IndexWorkerMock.clear()
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
                   must: [
                     %{
                       multi_match: %{
                         fields: ["ngram_name*^3"],
                         query: "foo",
                         type: "bool_prefix"
                       }
                     },
                     %{term: %{"domain_id" => 1234}},
                     %{bool: %{must_not: [%{term: %{"confidential.raw" => true}}]}},
                     %{term: %{"status" => "published"}}
                   ]
                 } = bool

          SearchHelpers.hits_response([bcv])
        end
      )

      params = %{filters: %{"domain_id" => [1234]}, query: "foo"}

      assert %{"data" => [%{"id" => ^id, "domain_parents" => domain_parents}]} =
               conn
               |> post(Routes.business_concept_version_search_path(conn, :search), params)
               |> json_response(:ok)

      assert domain_parents == [
               %{"id" => domain_id, "external_id" => domain_external_id, "name" => domain_name},
               %{"id" => parent_id, "external_id" => parent_external_id, "name" => parent_name}
             ]
    end

    @tag authentication: [role: "admin"]
    @tag :template
    test "show default lang content when conn locale is nil ", %{conn: conn} do
      content = %{
        "Field1" => %{"value" => "First field", "origin" => "user"},
        "Field2" => %{"value" => "Second field", "origin" => "user"}
      }

      bcv = insert(:business_concept_version, content: content, type: @template_name)

      expect(
        ElasticsearchMock,
        :request,
        fn _, :post, "/concepts/_search", %{from: 0, query: _}, _ ->
          SearchHelpers.hits_response([bcv])
        end
      )

      log =
        capture_log(fn ->
          assert %{
                   "data" => [
                     %{"content" => %{"Field1" => "First field", "Field2" => "Second field"}}
                   ]
                 } =
                   conn
                   |> Plug.Conn.assign(:locale, nil)
                   |> post(Routes.business_concept_version_search_path(conn, :search), %{})
                   |> json_response(:ok)
        end)

      assert log =~ """
             Language is not defined in the business_concept_version_search_view
             """
    end

    @tag authentication: [role: "admin"]
    test "return i18n content non-translatable fields ", %{conn: conn} do
      template_name = "complete_template"

      template = %{
        id: System.unique_integer([:positive]),
        label: "df_test",
        name: template_name,
        scope: "bg",
        content: @complete_content
      }

      CacheHelpers.insert_template(template)

      busines_concept_content = %{
        "df_description" => %{
          "value" => %{
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
          },
          "origin" => "user"
        },
        "basic_list" => %{"value" => "1", "origin" => "user"},
        "Identificador" => %{"value" => "foo", "origin" => "user"},
        "text_area" => %{"value" => "default_foo", "origin" => "user"}
      }

      %{id: bcv_id} =
        bcv =
        insert(:business_concept_version, content: busines_concept_content, type: template_name)

      i18n_content = %{
        "text_input" => %{"value" => "foo_translatable", "origin" => "user"},
        "text_area" => %{"value" => "bar_translatable", "origin" => "user"}
      }

      i18n_name = "i18n_name"

      %{lang: lang} =
        insert(:i18n_content,
          business_concept_version_id: bcv_id,
          content: i18n_content,
          lang: "es",
          name: i18n_name
        )

      expect(
        ElasticsearchMock,
        :request,
        fn _, :post, "/concepts/_search", %{from: 0, query: _}, _ ->
          SearchHelpers.hits_response([bcv])
        end
      )

      assert %{"data" => [%{"name" => ^i18n_name, "content" => content}]} =
               conn
               |> Plug.Conn.assign(:locale, lang)
               |> post(Routes.business_concept_version_search_path(conn, :search), %{})
               |> json_response(:ok)

      assert %{
               "Identificador" => "foo",
               "basic_list" => "1",
               "df_description" => "",
               "enriched_text" => "",
               "text_area" => "bar_translatable",
               "text_input" => "foo_translatable"
             } = content
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

        params = %{filters: %{"status" => ["published", "rejected"]}}

        assert %{"data" => [%{"id" => ^id}]} =
                 conn
                 |> post(Routes.business_concept_version_search_path(conn, :search), params)
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
               |> post(Routes.business_concept_version_search_path(conn, :search),
                 only_linkable: true
               )
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
               |> post(Routes.business_concept_version_search_path(conn, :search),
                 only_linkable: true
               )
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
          assert %{bool: %{must: [%{term: %{"domain_ids" => ^domain_id2}}, _, _]}} = query
          SearchHelpers.hits_response([bcv])
      end)

      put_session_permissions(claims, %{
        "view_draft_business_concepts" => [domain_id1, domain_id2],
        "manage_business_concept_links" => [domain_id2]
      })

      assert %{"data" => data} =
               conn
               |> post(Routes.business_concept_version_search_path(conn, :search),
                 only_linkable: true
               )
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
                     %{
                       multi_match: %{
                         fields: ["ngram_name*^3"],
                         query: "foo",
                         type: "bool_prefix"
                       }
                     },
                     %{term: %{"domain_id" => 1234}},
                     _status_filter,
                     _confidential_filter
                   ]
                 } = bool

          SearchHelpers.hits_response([bcv])
        end
      )

      params = %{must: %{"domain_id" => [1234]}, query: "foo"}

      assert %{"data" => [%{"id" => ^id, "domain_parents" => domain_parents}]} =
               conn
               |> post(Routes.business_concept_version_search_path(conn, :search), params)
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
                 |> post(Routes.business_concept_version_search_path(conn, :search), params)
                 |> json_response(:ok)
      end
    end
  end

  describe "POST /api/business_concept_versions/search scroll" do
    @tag authentication: [role: "admin"]
    test "includes scroll_id in response",
         %{conn: conn} do
      business_concept_versions =
        Enum.map(1..5, fn _ ->
          insert(:business_concept_version)
        end)

      ElasticsearchMock
      |> expect(:request, fn _, :post, "/concepts/_search", _, [params: %{"scroll" => "1m"}] ->
        SearchHelpers.scroll_response(business_concept_versions, 7)
      end)
      |> expect(:request, fn _, :post, "/_search/scroll", %{"scroll_id" => "some_scroll_id"}, _ ->
        SearchHelpers.scroll_response([], 7)
      end)

      assert %{"data" => data, "scroll_id" => scroll_id} =
               conn
               |> post(Routes.business_concept_version_search_path(conn, :search), %{
                 "filters" => %{"all" => true},
                 "size" => 5,
                 "scroll" => "1m"
               })
               |> json_response(:ok)

      assert length(data) == 5

      assert %{"data" => [], "scroll_id" => _scroll_id} =
               conn
               |> post(Routes.business_concept_version_search_path(conn, :search), %{
                 "scroll_id" => scroll_id
               })
               |> json_response(:ok)
    end
  end

  describe "POST /api/business_concept_versions/search last_change_at" do
    @tag authentication: [role: "admin"]
    test "filters by last_change_at field",
         %{conn: conn} do
      now = NaiveDateTime.local_now()

      ElasticsearchMock
      |> expect(:request, fn _,
                             :post,
                             "/concepts/_search",
                             %{
                               query: query
                             },
                             [params: %{"track_total_hits" => "true"}] ->
        assert %{
                 bool: %{
                   must: %{
                     range: %{"last_change_at" => %{"gt" => ^now}}
                   }
                 }
               } = query

        SearchHelpers.hits_response([])
      end)

      post(conn, Routes.business_concept_version_search_path(conn, :search), %{
        "must" => %{"last_change_at" => %{"gt" => now}}
      })
    end
  end
end
