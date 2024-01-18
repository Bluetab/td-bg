defmodule TdBg.BusinessConcepts.SearchTest do
  use TdBgWeb.ConnCase

  import Mox

  alias TdBg.BusinessConcept.Search

  setup do
    start_supervised!(TdCore.Search.Cluster)
    :ok
  end

  setup :verify_on_exit!

  describe "Search.search_business_concept_versions/4" do
    @tag authentication: [role: "user"]
    test "posts a meaningful search request and handles response correctly", %{claims: claims} do
      %{id: domain_id0} = CacheHelpers.insert_domain()
      %{id: domain_id1} = CacheHelpers.insert_domain(parent_id: domain_id0)
      %{id: domain_id2} = CacheHelpers.insert_domain(parent_id: domain_id1)
      %{id: domain_id3} = CacheHelpers.insert_domain()
      %{id: domain_id4} = CacheHelpers.insert_domain()

      %{id: id} = bcv = insert(:business_concept_version, domain_id: domain_id2)
      CacheHelpers.put_default_permissions(["view_published_business_concepts"])

      put_session_permissions(claims, %{
        "view_approval_pending_business_concepts" => [domain_id3],
        "view_draft_business_concepts" => [domain_id3],
        "manage_confidential_business_concepts" => [domain_id1],
        "view_rejected_business_concepts" => [domain_id4]
      })

      ElasticsearchMock
      |> expect(:request, fn
        _, :post, "/concepts/_search", %{from: 50, query: query, size: 10, sort: "foo"}, opts ->
          assert opts == [params: %{"track_total_hits" => "true"}]

          assert %{bool: %{filter: [status_filter, confidential_filter]}} = query

          assert status_filter == %{
                   bool: %{
                     should: [
                       %{
                         bool: %{
                           filter: [
                             %{term: %{"status" => "rejected"}},
                             %{term: %{"domain_ids" => domain_id4}}
                           ]
                         }
                       },
                       %{
                         bool: %{
                           filter: [
                             %{terms: %{"status" => ["draft", "pending_approval"]}},
                             %{term: %{"domain_ids" => domain_id3}}
                           ]
                         }
                       },
                       %{term: %{"status" => "published"}}
                     ]
                   }
                 }

          assert confidential_filter == %{
                   bool: %{
                     should: [
                       %{terms: %{"domain_ids" => [domain_id1, domain_id2]}},
                       %{bool: %{must_not: [%{term: %{"confidential.raw" => true}}]}}
                     ]
                   }
                 }

          SearchHelpers.hits_response([bcv], 55)
      end)

      assert %{results: [%{"id" => ^id, "domain_parents" => domain_parents}], total: 55} =
               Search.search_business_concept_versions(
                 %{"sort" => "foo", "query" => "bar"},
                 claims,
                 5,
                 10
               )

      assert [%{id: ^domain_id2}, %{id: ^domain_id1}, %{id: ^domain_id0}] = domain_parents
    end

    @tag authentication: [role: "user"]
    test "posts a meaningful search request and handles response correctly with must params", %{
      claims: claims
    } do
      %{id: domain_id0} = CacheHelpers.insert_domain()
      %{id: domain_id1} = CacheHelpers.insert_domain(parent_id: domain_id0)
      %{id: domain_id2} = CacheHelpers.insert_domain(parent_id: domain_id1)
      %{id: domain_id3} = CacheHelpers.insert_domain()
      %{id: domain_id4} = CacheHelpers.insert_domain()

      %{id: id} = bcv = insert(:business_concept_version, domain_id: domain_id2)
      CacheHelpers.put_default_permissions(["view_published_business_concepts"])

      put_session_permissions(claims, %{
        "view_approval_pending_business_concepts" => [domain_id3],
        "view_draft_business_concepts" => [domain_id3],
        "manage_confidential_business_concepts" => [domain_id1],
        "view_rejected_business_concepts" => [domain_id4]
      })

      ElasticsearchMock
      |> expect(:request, fn
        _, :post, "/concepts/_search", %{from: 50, query: query, size: 10, sort: "foo"}, opts ->
          assert opts == [params: %{"track_total_hits" => "true"}]

          assert %{bool: %{must: [simple_query, status_filter, confidential_filter]}} = query

          assert simple_query == %{simple_query_string: %{query: "bar*"}}

          %{
            bool: %{
              should: [
                %{
                  bool: %{
                    filter: first_terms
                  }
                },
                %{
                  bool: %{
                    filter: second_terms
                  }
                },
                %{term: %{"status" => "published"}}
              ]
            }
          } = status_filter

          assert Enum.sort(first_terms) ==
                   Enum.sort([
                     %{term: %{"status" => "rejected"}},
                     %{term: %{"domain_ids" => domain_id4}}
                   ])

          assert Enum.sort(second_terms) ==
                   Enum.sort([
                     %{terms: %{"status" => ["draft", "pending_approval"]}},
                     %{term: %{"domain_ids" => domain_id3}}
                   ])

          assert confidential_filter == %{
                   bool: %{
                     should: [
                       %{terms: %{"domain_ids" => [domain_id1, domain_id2]}},
                       %{bool: %{must_not: [%{term: %{"confidential.raw" => true}}]}}
                     ]
                   }
                 }

          SearchHelpers.hits_response([bcv], 55)
      end)

      assert %{results: [%{"id" => ^id, "domain_parents" => domain_parents}], total: 55} =
               Search.search_business_concept_versions(
                 %{"must" => %{}, "sort" => "foo", "query" => "bar"},
                 claims,
                 5,
                 10
               )

      assert [%{id: ^domain_id2}, %{id: ^domain_id1}, %{id: ^domain_id0}] = domain_parents
    end
  end
end
