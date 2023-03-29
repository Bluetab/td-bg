defmodule TdBg.UploadTest do
  use TdBg.DataCase

  import Mox

  alias TdBg.BusinessConcept.Upload
  alias TdBg.BusinessConcepts
  alias TdBg.ElasticsearchMock
  alias TdCache.HierarchyCache

  setup_all do
    start_supervised!(TdBg.Cache.ConceptLoader)
    start_supervised!(TdBg.Search.Cluster)
    start_supervised!(TdBg.Search.IndexWorker)
    :ok
  end

  setup :verify_on_exit!

  setup _context do
    %{id: template_id} =
      template =
      Templates.create_template(%{
        name: "term",
        content: [
          %{
            "name" => "group",
            "fields" => [
              %{
                "cardinality" => "1",
                "default" => "",
                "description" => "description",
                "label" => "critical term",
                "name" => "critical",
                "type" => "string",
                "values" => %{
                  "fixed" => ["Yes", "No"]
                }
              },
              %{
                "cardinality" => "+",
                "description" => "description",
                "label" => "Role",
                "name" => "role",
                "type" => "user"
              },
              %{
                "name" => "hierarchy_name_1",
                "type" => "hierarchy",
                "cardinality" => "?",
                "values" => %{"hierarchy" => 1}
              },
              %{
                "name" => "hierarchy_name_2",
                "type" => "hierarchy",
                "cardinality" => "*",
                "values" => %{"hierarchy" => 1}
              }
            ]
          }
        ],
        scope: "test",
        label: "term",
        id: "999"
      })

    on_exit(fn ->
      Templates.delete(template_id)
    end)

    %{id: hierarchy_id} = hierarchy = create_hierarchy()
    HierarchyCache.put(hierarchy)
    on_exit(fn -> HierarchyCache.delete(hierarchy_id) end)

    [template: template, hierarchy: hierarchy]
  end

  describe "business_concept_upload" do
    setup :set_mox_from_context

    test "from_csv/3 uploads business concept versions with valid data" do
      ElasticsearchMock
      |> expect(:request, fn _, :post, "/concepts/_doc/_bulk", _, [] ->
        SearchHelpers.bulk_index_response()
      end)

      claims = build(:claims)
      insert(:domain, external_id: "domain")
      business_concept_upload = %{path: "test/fixtures/upload.csv"}

      assert {:ok, [concept_id | _]} =
               Upload.from_csv(business_concept_upload, claims, fn _, _ -> true end)

      version = BusinessConcepts.get_last_version_by_business_concept_id!(concept_id)
      concept = Map.get(version, :business_concept)
      assert Map.get(concept, :confidential)
      assert version |> Map.get(:content) |> Map.get("role") == ["Role"]
    end

    test "from_csv/3 uploads business concept versions with hierarchy data" do
      ElasticsearchMock
      |> expect(:request, fn _, :post, "/concepts/_doc/_bulk", _, [] ->
        SearchHelpers.bulk_index_response()
      end)

      claims = build(:claims)
      insert(:domain, external_id: "domain")
      business_concept_upload = %{path: "test/fixtures/upload_hierarchy.csv"}

      assert {:ok, [concept_id | _]} =
               Upload.from_csv(business_concept_upload, claims, fn _, _ -> true end)

      version = BusinessConcepts.get_last_version_by_business_concept_id!(concept_id)

      assert %{
               "hierarchy_name_1" => "1_2",
               "hierarchy_name_2" => ["1_2", "1_1"]
             } = Map.get(version, :content)
    end

    test "from_csv/3 get error business concept versions with invalid hierarchy data" do
      claims = build(:claims)
      insert(:domain, external_id: "domain")
      business_concept_upload = %{path: "test/fixtures/upload_invalid_hierarchy.csv"}

      assert {:error, changeset} =
               Upload.from_csv(business_concept_upload, claims, fn _, _ -> true end)

      assert [
               hierarchy_name_1: {"has more than one node children_2"},
               hierarchy_name_2: {"has more than one node children_2"}
             ] =
               changeset
               |> Map.get(:errors)
    end

    test "from_csv/3 returns error on invalid content" do
      claims = build(:claims)
      insert(:domain, external_id: "domain")
      business_concept_upload = %{path: "test/fixtures/incorrect_upload.csv"}

      assert {:error, changeset} =
               Upload.from_csv(business_concept_upload, claims, fn _, _ -> true end)

      message =
        changeset
        |> Map.get(:errors)
        |> Keyword.get(:critical)
        |> elem(0)

      assert message == "is invalid"
    end

    test "from_csv/3 Does not upload business concept versions without permissions" do
      claims = build(:claims)
      insert(:domain, external_id: "domain", name: "fobidden_domain")
      business_concept_upload = %{path: "test/fixtures/upload.csv"}

      assert {:error, %{error: :forbidden, domain: "fobidden_domain"}} =
               Upload.from_csv(business_concept_upload, claims, fn _, _ -> false end)
    end
  end

  defp create_hierarchy do
    hierarchy_id = 1

    %{
      id: hierarchy_id,
      name: "name_#{hierarchy_id}",
      nodes: [
        build(:node, %{
          node_id: 1,
          parent_id: nil,
          name: "father",
          path: "/father",
          hierarchy_id: hierarchy_id
        }),
        build(:node, %{
          node_id: 2,
          parent_id: 1,
          name: "children_1",
          path: "/father/children_1",
          hierarchy_id: hierarchy_id
        }),
        build(:node, %{
          node_id: 3,
          parent_id: 1,
          name: "children_2",
          path: "/father/children_2",
          hierarchy_id: hierarchy_id
        }),
        build(:node, %{
          node_id: 4,
          parent_id: nil,
          name: "children_2",
          path: "/children_2",
          hierarchy_id: hierarchy_id
        })
      ]
    }
  end
end
