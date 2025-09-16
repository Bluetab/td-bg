defmodule TdBg.BusinessConcepts.Search.SuggestionsTest do
  use TdBgWeb.ConnCase

  alias TdBg.BusinessConcepts.Search.Suggestions
  alias TdCluster.TestHelpers.TdDdMock

  describe "knn/2" do
    @tag authentication: [role: "admin"]
    test "knn search with default params", %{claims: claims} do
      id = 1
      resource = %{"type" => "structures", "id" => id}

      TdDdMock.generate_vector(&Mox.expect/4, 1, nil, {:ok, {"default", [54.0, 10.2, -2.0]}})

      Mox.expect(ElasticsearchMock, :request, fn _, :post, "/concepts/_search", request, _ ->
        assert request == %{
                 sort: ["_score"],
                 _source: %{excludes: ["embeddings"]},
                 knn: %{
                   "field" => "embeddings.vector_default",
                   "filter" => %{
                     bool: %{
                       must: [
                         %{
                           terms: %{
                             "status" => ["draft", "pending_approval", "published", "rejected"]
                           }
                         },
                         %{term: %{"current" => true}}
                       ]
                     }
                   },
                   "k" => 10,
                   "num_candidates" => 100,
                   "query_vector" => [54.0, 10.2, -2.0],
                   "similarity" => 0.6
                 }
               }

        SearchHelpers.hits_response([insert(:business_concept_version)])
      end)

      assert [result] = Suggestions.knn(claims, %{"resource" => resource})
      assert result["similarity"] == 1.0
    end

    @tag authentication: [role: "admin"]
    test "knn search excludes previous link structure ids from search", %{claims: claims} do
      id = 1
      links = [%{"resource_id" => "1"}]
      resource = %{"type" => "structures", "id" => id, "links" => links}

      TdDdMock.generate_vector(&Mox.expect/4, id, nil, {:ok, {"default", [54.0, 10.2, -2.0]}})

      Mox.expect(ElasticsearchMock, :request, fn
        _, :post, "/concepts/_search", request, _ ->
          assert request == %{
                   sort: ["_score"],
                   _source: %{excludes: ["embeddings"]},
                   knn: %{
                     "field" => "embeddings.vector_default",
                     "filter" => %{
                       bool: %{
                         must: [
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
                     "num_candidates" => 100,
                     "query_vector" => [54.0, 10.2, -2.0],
                     "similarity" => 0.6
                   }
                 }

          SearchHelpers.hits_response([insert(:business_concept_version)])
      end)

      assert [result] = Suggestions.knn(claims, %{"resource" => resource})
      assert result["similarity"] == 1.0
    end

    @tag authentication: [role: "admin"]
    test "knn search overrides default params", %{claims: claims} do
      id = 1

      params = %{
        "resource" => %{
          "id" => id,
          "type" => "structures"
        },
        "num_candidates" => 500,
        "k" => 22,
        "collection_name" => "foo",
        "similarity" => 0.8
      }

      TdDdMock.generate_vector(&Mox.expect/4, 1, "foo", {:ok, {"foo", [54.0, 10.2, -2.0]}})

      Mox.expect(ElasticsearchMock, :request, fn
        _, :post, "/concepts/_search", request, _ ->
          assert request == %{
                   sort: ["_score"],
                   _source: %{excludes: ["embeddings"]},
                   knn: %{
                     "field" => "embeddings.vector_foo",
                     "filter" => %{
                       bool: %{
                         must: [
                           %{
                             terms: %{
                               "status" => ["draft", "pending_approval", "published", "rejected"]
                             }
                           },
                           %{term: %{"current" => true}}
                         ]
                       }
                     },
                     "k" => 22,
                     "num_candidates" => 500,
                     "query_vector" => [54.0, 10.2, -2.0],
                     "similarity" => 0.8
                   }
                 }

          SearchHelpers.hits_response([insert(:business_concept_version)])
      end)

      [result] = Suggestions.knn(claims, params)

      assert result["similarity"] == 1.0
    end
  end
end
