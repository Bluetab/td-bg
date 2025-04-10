defmodule TdBgWeb.BusinessConceptLinkControllerTest do
  use TdBgWeb.ConnCase

  import Mox

  describe "POST /api/business_concept_versions/links/download" do
    setup do
      bcv = insert(:business_concept_version)
      CacheHelpers.put_concept(bcv.business_concept, bcv)
      data_structure = CacheHelpers.insert_data_structure()

      CacheHelpers.insert_link(
        bcv.business_concept_id,
        "business_concept",
        "data_structure",
        data_structure.id
      )

      [
        claims: build(:claims, role: "admin"),
        data_structure: data_structure,
        concept: bcv
      ]
    end

    @tag authentication: [role: "admin"]
    test "downloads file content with links", %{
      conn: conn,
      data_structure: data_structure,
      concept: bcv
    } do
      expect(ElasticsearchMock, :request, fn _, :post, "/concepts/_pit", %{}, opts ->
        assert opts == [params: %{"keep_alive" => "1m"}]
        {:ok, %{"id" => "foo"}}
      end)

      expect(ElasticsearchMock, :request, fn _, :post, "/_search", query, _opts ->
        assert query == %{
                 size: 1_000,
                 sort: ["_id"],
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

        SearchHelpers.search_after_response([bcv])
      end)

      expect(ElasticsearchMock, :request, fn _, :post, "/_search", query, _opts ->
        assert query == %{
                 size: 1_000,
                 sort: ["_id"],
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
         %HTTPoison.Response{
           status_code: 200,
           body: %{"num_freed" => 1, "succeeded" => true},
           headers: [
             {"content-type", "application/json; charset=UTF-8"},
             {"content-length", "32"}
           ],
           request_url: "http://elastic:9200/_pit",
           request: %HTTPoison.Request{
             method: :delete,
             url: "http://elastic:9200/_pit",
             headers: [{"Content-Type", "application/json"}],
             body: "{\"id\":\"foo\"}",
             params: %{},
             options: [timeout: 5_000, recv_timeout: 40_000]
           }
         }}
      end)

      assert %{resp_body: body} =
               post(conn, Routes.business_concept_link_path(conn, :download, %{"query" => "bar"}))

      assert {:ok, workbook} = XlsxReader.open(body, source: :binary)
      assert {:ok, [headers | content]} = XlsxReader.sheet(workbook, "links_to_structures")

      assert headers == [
               "id",
               "current_version_id",
               "concept_name",
               "domain_external_id",
               "domain_name",
               "structure_external_id",
               "structure_name",
               "structure_system",
               "path",
               "link_type"
             ]

      assert row =
               Enum.find(content, fn row ->
                 row |> Enum.at(0) |> trunc() == bcv.business_concept_id and
                   row |> Enum.at(1) |> trunc() == bcv.id
               end)

      assert [
               bcv.business_concept_id * 1.0,
               bcv.id * 1.0,
               bcv.name,
               bcv.business_concept.domain.external_id,
               bcv.business_concept.domain.name,
               Map.get(data_structure, :external_id, ""),
               Map.get(data_structure, :name, ""),
               get_in(data_structure, [:system, :external_id]) || "",
               Enum.join(Map.get(data_structure, :path, []), " > "),
               Enum.join(Map.get(data_structure, :tags, []), ", ")
             ] == row
    end
  end
end
