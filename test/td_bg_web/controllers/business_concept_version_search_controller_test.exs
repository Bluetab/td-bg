defmodule TdBgWeb.BusinessConceptVersionSearchControllerTest do
  use TdBgWeb.ConnCase
  use PhoenixSwagger.SchemaTest, "priv/static/swagger.json"

  import ExUnit.CaptureLog
  import Mox

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
                     %{simple_query_string: %{query: "foo*"}},
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
                     %{simple_query_string: %{query: "foo*"}},
                     %{term: %{"domain_id" => 1234}},
                     _status_filter,
                     _confidential_filter
                   ],
                   should: %{multi_match: %{operator: "and", query: "foo*", type: "best_fields"}}
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
