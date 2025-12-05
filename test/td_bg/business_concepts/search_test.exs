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

          assert %{
                   bool: %{
                     filter: [confidential_filter, status_filter],
                     must: must,
                     should: should
                   }
                 } = query

          assert must == %{
                   multi_match: %{
                     fields: ["ngram_name*^3"],
                     query: "bar",
                     type: "bool_prefix",
                     lenient: true,
                     fuzziness: "AUTO"
                   }
                 }

          assert should == [
                   %{
                     multi_match: %{
                       type: "phrase_prefix",
                       fields: ["name^3"],
                       query: "bar",
                       lenient: true,
                       boost: 4.0
                     }
                   },
                   %{
                     simple_query_string: %{
                       fields: ["name^3"],
                       query: "\"bar\"",
                       quote_field_suffix: ".exact",
                       boost: 4.0
                     }
                   }
                 ]

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

          assert %{bool: %{must: must, filter: [confidential_filter, status_filter]}} = query

          assert must == %{
                   simple_query_string: %{
                     fields: ["name^3"],
                     query: "\"bar\"",
                     quote_field_suffix: ".exact"
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

          assert %{
                   bool: %{
                     must: must,
                     should: should,
                     filter: [confidential_filter, status_filter]
                   }
                 } = query

          assert must == %{
                   multi_match: %{
                     fields: ["ngram_name*^3"],
                     query: "bar",
                     type: "bool_prefix",
                     lenient: true,
                     fuzziness: "AUTO"
                   }
                 }

          assert should == [
                   %{
                     multi_match: %{
                       type: "phrase_prefix",
                       fields: ["name^3"],
                       query: "bar",
                       lenient: true,
                       boost: 4.0
                     }
                   },
                   %{
                     simple_query_string: %{
                       fields: ["name^3"],
                       query: "\"bar\"",
                       quote_field_suffix: ".exact",
                       boost: 4.0
                     }
                   }
                 ]

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
                     filter: %{match_all: %{}},
                     should: [
                       %{
                         multi_match: %{
                           type: "phrase_prefix",
                           fields: ["name^3"],
                           query: "bar",
                           lenient: true,
                           boost: 4.0
                         }
                       },
                       %{
                         simple_query_string: %{
                           fields: ["name^3"],
                           query: "\"bar\"",
                           quote_field_suffix: ".exact",
                           boost: 4.0
                         }
                       }
                     ],
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
                     filter: %{match_all: %{}},
                     should: [
                       %{
                         multi_match: %{
                           type: "phrase_prefix",
                           fields: ["name^3"],
                           query: "bar",
                           lenient: true,
                           boost: 4.0
                         }
                       },
                       %{
                         simple_query_string: %{
                           fields: ["name^3"],
                           query: "\"bar\"",
                           quote_field_suffix: ".exact",
                           boost: 4.0
                         }
                       }
                     ],
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
                     filter: %{match_all: %{}},
                     should: [
                       %{
                         multi_match: %{
                           type: "phrase_prefix",
                           fields: ["name^3"],
                           query: "bar",
                           lenient: true,
                           boost: 4.0
                         }
                       },
                       %{
                         simple_query_string: %{
                           fields: ["name^3"],
                           query: "\"bar\"",
                           quote_field_suffix: ".exact",
                           boost: 4.0
                         }
                       }
                     ],
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

  describe "Search.vector" do
    @tag authentication: [role: "admin"]
    test "puts vector search in elastic", %{claims: claims} do
      expect(ElasticsearchMock, :request, fn _, :post, "/concepts/_search", request, _ ->
        assert request == %{
                 sort: ["_score"],
                 _source: %{excludes: ["embeddings"]},
                 knn: %{
                   "field" => "embeddings.vector_foo",
                   "filter" => %{
                     bool: %{
                       filter: [
                         %{
                           terms: %{
                             "status" => ["draft", "pending_approval", "published", "rejected"]
                           }
                         },
                         %{term: %{"current" => true}}
                       ],
                       must_not: %{term: %{"business_concept_ids" => "1"}}
                     }
                   },
                   "k" => 10,
                   "num_candidates" => 200,
                   "query_vector" => [54.0, 10.2, -2.0],
                   "similarity" => 0.5
                 }
               }

        SearchHelpers.hits_response([insert(:business_concept_version)], 1)
      end)

      params = %{
        "field" => "embeddings.vector_foo",
        "k" => 10,
        "similarity" => 0.5,
        "num_candidates" => 200,
        "query_vector" => [54.0, 10.2, -2.0],
        "must" => %{
          "current" => true,
          "status" => ["pending_approval", "draft", "rejected", "published"]
        },
        "must_not" => %{"business_concept_ids" => ["1"]}
      }

      assert [concept] = Search.vector(claims, params, similarity: :cosine)
      assert concept["similarity"] == 1.0
    end

    @tag authentication: [role: "user"]
    test "puts domain filters in vector search", %{claims: claims} do
      %{id: domain_id} = CacheHelpers.insert_domain()
      bcv = insert(:business_concept_version, domain_id: domain_id)
      CacheHelpers.put_default_permissions(["view_published_business_concepts"])
      put_session_permissions(claims, %{"view_approval_pending_business_concepts" => [domain_id]})

      expect(ElasticsearchMock, :request, fn _, :post, "/concepts/_search", request, _ ->
        assert request == %{
                 sort: ["_score"],
                 _source: %{excludes: ["embeddings"]},
                 knn: %{
                   "field" => "embeddings.vector_foo",
                   "filter" => %{
                     bool: %{
                       filter: [
                         %{
                           terms: %{
                             "status" => ["draft", "pending_approval", "published", "rejected"]
                           }
                         },
                         %{term: %{"current" => true}},
                         %{bool: %{must_not: [%{term: %{"confidential.raw" => true}}]}},
                         %{
                           bool: %{
                             should: [
                               %{
                                 bool: %{
                                   filter: [
                                     %{term: %{"status" => "pending_approval"}},
                                     %{term: %{"domain_ids" => domain_id}}
                                   ]
                                 }
                               },
                               %{term: %{"status" => "published"}}
                             ]
                           }
                         }
                       ],
                       must_not: %{term: %{"business_concept_ids" => "1"}}
                     }
                   },
                   "k" => 10,
                   "num_candidates" => 200,
                   "query_vector" => [54.0, 10.2, -2.0],
                   "similarity" => 0.5
                 }
               }

        SearchHelpers.hits_response([bcv], 1)
      end)

      params = %{
        "field" => "embeddings.vector_foo",
        "k" => 10,
        "similarity" => 0.5,
        "num_candidates" => 200,
        "query_vector" => [54.0, 10.2, -2.0],
        "must" => %{
          "current" => true,
          "status" => ["pending_approval", "draft", "rejected", "published"]
        },
        "must_not" => %{"business_concept_ids" => ["1"]}
      }

      assert [concept] = Search.vector(claims, params, similarity: :cosine)
      assert concept["similarity"] == 1.0
    end
  end
end
