defmodule TdBgWeb.SuggestionControllerTest do
  use TdBgWeb.ConnCase

  import Routes

  alias TdCluster.TestHelpers.TdAiMock
  alias TdCluster.TestHelpers.TdDdMock

  describe "search" do
    @tag authentication: [role: "user"]
    test "knn search for concept resource with default attrs", %{conn: conn, claims: claims} do
      %{id: domain_id} = CacheHelpers.insert_domain()
      version = insert(:business_concept_version)

      put_session_permissions(claims, domain_id, [
        :view_business_concept,
        :view_published_business_concepts
      ])

      id = 1

      resource = %{
        "type" => "structures",
        "id" => id,
        "links" => [
          %{
            "resource_id" => "1",
            "name" => "name",
            "external_id" => "external_id",
            "type" => "type",
            "path" => ["1", "2"],
            "description" => "description"
          }
        ]
      }

      TdAiMock.Indices.exists_enabled?(&Mox.expect/4, {:ok, true})

      TdDdMock.generate_vector(
        &Mox.expect/4,
        1,
        nil,
        {:ok, {"default_collection_name", [54.0, 10.2, -2.0]}}
      )

      Mox.expect(ElasticsearchMock, :request, fn
        _, :post, "/concepts/_search", %{knn: knn}, _ ->
          assert knn == %{
                   "field" => "embeddings.vector_default_collection_name",
                   "filter" => %{
                     bool: %{
                       must: [
                         %{
                           terms: %{
                             "status" => ["draft", "pending_approval", "published", "rejected"]
                           }
                         },
                         %{term: %{"current" => true}},
                         %{bool: %{must_not: [%{term: %{"confidential.raw" => true}}]}},
                         %{
                           bool: %{
                             filter: [
                               %{term: %{"status" => "published"}},
                               %{term: %{"domain_ids" => domain_id}}
                             ]
                           }
                         }
                       ],
                       must_not: %{term: %{"business_concept_ids" => "1"}}
                     }
                   },
                   "k" => 10,
                   "num_candidates" => 100,
                   "query_vector" => [54.0, 10.2, -2.0],
                   "similarity" => 0.60
                 }

          SearchHelpers.hits_response([version])
      end)

      assert %{"data" => [result]} =
               conn
               |> Plug.Conn.assign(:locale, "es")
               |> post(suggestion_path(conn, :search), %{"resource" => resource})
               |> json_response(:ok)

      assert result["business_concept_id"] == version.business_concept_id
      assert result["id"] == version.id
      assert result["similarity"] == 1.0
    end
  end
end
