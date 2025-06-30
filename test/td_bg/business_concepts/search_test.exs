defmodule TdBg.BusinessConcepts.SearchTest do
  use TdBgWeb.ConnCase

  import Mox
  import TdBg.TestOperators

  alias TdBg.BusinessConcept.Search

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

          assert %{bool: %{must: [query_filter, confidential_filter, status_filter]}} = query

          assert query_filter == %{
                   multi_match: %{
                     fields: ["ngram_name*^3"],
                     query: "bar",
                     type: "bool_prefix",
                     lenient: true,
                     fuzziness: "AUTO"
                   }
                 }

          assert %{bool: %{should: should}} = status_filter

          assert_lists_equal(should, [
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
          ])

          assert %{
                   bool: %{
                     should: [
                       %{terms: %{"domain_ids" => domain_ids}},
                       %{bool: %{must_not: [%{term: %{"confidential.raw" => true}}]}}
                     ]
                   }
                 } = confidential_filter

          assert [domain_id1, domain_id2] ||| domain_ids
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
    test "posts a meaningful search request with wildcard and handles response correctly", %{
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

      expect(ElasticsearchMock, :request, fn
        _, :post, "/concepts/_search", %{from: 50, query: query, size: 10, sort: "foo"}, opts ->
          assert opts == [params: %{"track_total_hits" => "true"}]

          assert %{bool: %{must: [query_filter, confidential_filter, status_filter]}} = query

          assert query_filter == %{simple_query_string: %{fields: ["name*"], query: "\"bar\""}}

          assert %{bool: %{should: should}} = status_filter

          assert_lists_equal(should, [
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
          ])

          assert %{
                   bool: %{
                     should: [
                       %{terms: %{"domain_ids" => domain_ids}},
                       %{bool: %{must_not: [%{term: %{"confidential.raw" => true}}]}}
                     ]
                   }
                 } = confidential_filter

          assert [domain_id1, domain_id2] ||| domain_ids
          SearchHelpers.hits_response([bcv], 55)
      end)

      assert %{results: [%{"id" => ^id, "domain_parents" => domain_parents}], total: 55} =
               Search.search_business_concept_versions(
                 %{"sort" => "foo", "query" => "\"bar\""},
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

          assert %{bool: %{must: [ngram_query, confidential_filter, status_filter]}} = query

          assert ngram_query == %{
                   multi_match: %{
                     fields: ["ngram_name*^3"],
                     query: "bar",
                     type: "bool_prefix",
                     lenient: true,
                     fuzziness: "AUTO"
                   }
                 }

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

          assert [
                   %{term: %{"status" => "rejected"}},
                   %{term: %{"domain_ids" => domain_id4}}
                 ] in [first_terms, second_terms]

          assert [
                   %{terms: %{"status" => ["draft", "pending_approval"]}},
                   %{term: %{"domain_ids" => domain_id3}}
                 ] in [first_terms, second_terms]

          assert %{
                   bool: %{
                     should: [
                       %{terms: %{"domain_ids" => domain_ids}},
                       %{bool: %{must_not: [%{term: %{"confidential.raw" => true}}]}}
                     ]
                   }
                 } = confidential_filter

          assert [domain_id1, domain_id2] ||| domain_ids

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

  describe "Search.stream_all/3" do
    @tag authentication: [role: "admin"]
    test "streams over a list of business concept versions", %{claims: claims} do
      bcv1 = insert(:business_concept_version)
      bcv2 = insert(:business_concept_version)

      expect(ElasticsearchMock, :request, fn _, :post, "/concepts/_pit", %{}, opts ->
        assert opts == [params: %{"keep_alive" => "1m"}]
        {:ok, %{"id" => "foo"}}
      end)

      expect(ElasticsearchMock, :request, fn _, :post, "/_search", query, _opts ->
        assert query == %{
                 size: 1,
                 sort: "foo",
                 query: %{
                   bool: %{
                     must: %{
                       multi_match: %{
                         type: "bool_prefix",
                         fields: ["ngram_name*^3"],
                         query: "bar",
                         lenient: true,
                         fuzziness: "AUTO"
                       }
                     }
                   }
                 },
                 pit: %{id: "foo", keep_alive: "1m"}
               }

        SearchHelpers.search_after_response([bcv1])
      end)

      expect(ElasticsearchMock, :request, fn _, :post, "/_search", query, _opts ->
        assert query == %{
                 size: 1,
                 sort: "foo",
                 query: %{
                   bool: %{
                     must: %{
                       multi_match: %{
                         type: "bool_prefix",
                         fields: ["ngram_name*^3"],
                         query: "bar",
                         lenient: true,
                         fuzziness: "AUTO"
                       }
                     }
                   }
                 },
                 pit: %{id: "foo", keep_alive: "1m"},
                 search_after: ["search after cursor"]
               }

        SearchHelpers.search_after_response([bcv2])
      end)

      expect(ElasticsearchMock, :request, fn _, :post, "/_search", query, _opts ->
        assert query == %{
                 size: 1,
                 sort: "foo",
                 query: %{
                   bool: %{
                     must: %{
                       multi_match: %{
                         type: "bool_prefix",
                         fields: ["ngram_name*^3"],
                         query: "bar",
                         lenient: true,
                         fuzziness: "AUTO"
                       }
                     }
                   }
                 },
                 pit: %{id: "foo", keep_alive: "1m"},
                 search_after: ["search after cursor"]
               }

        SearchHelpers.search_after_response([])
      end)

      expect(ElasticsearchMock, :request, fn _, :delete, "/_pit", %{"id" => "foo"}, opts ->
        assert opts == []

        {:ok,
         %{
           status_code: 200,
           body: %{"num_freed" => 1, "succeeded" => true},
           headers: [
             {"content-type", "application/json; charset=UTF-8"},
             {"content-length", "32"}
           ],
           request_url: "http://elastic:9200/_pit",
           request: %{
             method: :delete,
             url: "http://elastic:9200/_pit",
             headers: [{"Content-Type", "application/json"}],
             body: "{\"id\":\"foo\"}",
             params: %{},
             options: [timeout: 5_000, recv_timeout: 40_000]
           }
         }}
      end)

      stream = Search.stream_all(claims, %{"sort" => "foo", "query" => "bar"}, 1)
      assert concepts = [_ | _] = stream |> Enum.to_list() |> List.flatten()
      assert Enum.count(concepts) == 2
      assert Enum.find(concepts, &(Map.get(&1, "id") == bcv1.id))
      assert Enum.find(concepts, &(Map.get(&1, "id") == bcv2.id))
    end
  end
end
