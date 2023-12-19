defmodule TdBg.BusinessConceptBulkUpdateTest do
  use TdBg.DataCase

  import Mox

  alias TdBg.BusinessConcept.BulkUpdate
  alias TdBg.BusinessConcepts
  alias TdCore.Search.MockIndexWorker
  alias TdCore.Utils.CollectionUtils

  setup_all do
    start_supervised!(TdCore.Search.Cluster)
    start_supervised!(TdBg.Cache.ConceptLoader)
    start_supervised!(TdCore.Search.IndexWorker)

    :ok
  end

  setup :verify_on_exit!

  setup _context do
    Templates.create_template(%{
      name: "template_test",
      content: [
        %{
          "name" => "group",
          "fields" => [
            %{
              "name" => "Field1",
              "type" => "string",
              "group" => "Multiple Group",
              "label" => "Field 1",
              "values" => nil,
              "cardinality" => "1"
            },
            %{
              "name" => "Field2",
              "type" => "string",
              "group" => "Multiple Group",
              "label" => "Field 2",
              "values" => nil,
              "cardinality" => "1"
            },
            %{
              "name" => "Field3",
              "type" => "string",
              "group" => "Multiple Group",
              "label" => "Field 3",
              "default" => 1,
              "values" => %{"fixed" => [1, 2, 3]},
              "cardinality" => "1"
            },
            %{
              "name" => "Field4",
              "type" => "string",
              "group" => "Multiple Group",
              "label" => "Field 4",
              "values" => %{"fixed" => [1, 2, 3]},
              "cardinality" => "*"
            },
            %{
              "name" => "Field5",
              "type" => "enriched_text",
              "group" => "Multiple Group",
              "label" => "Field 5",
              "cardinality" => "*"
            }
          ]
        }
      ],
      scope: "test",
      label: "template_label",
      id: "999"
    })

    on_exit(fn ->
      MockIndexWorker.clear()
    end)

    :ok
  end

  describe "BulkUpdate.update_all/3" do
    setup :set_mox_from_context

    test "update all business concept versions with valid data" do
      claims = build(:claims)

      d1 = insert(:domain, name: "d1")
      d2 = insert(:domain, name: "d2")
      d3 = insert(:domain, name: "d3")

      bc1 = insert(:business_concept, domain: d1, type: "template_test")
      bc2 = insert(:business_concept, domain: d2, type: "template_test")

      content = %{
        "Field1" => "First field",
        "Field2" => "Second field",
        "Field3" => 3,
        "Field4" => [1, 2],
        "Field5" => %{"foo" => "bar"}
      }

      update_content = %{
        "Field1" => "First udpate",
        "Field2" => "Second field",
        "Field3" => "",
        "Field4" => [],
        "Field5" => %{}
      }

      bc_version1 =
        insert(:business_concept_version,
          business_concept: bc1,
          content: content,
          name: "bc_version1"
        )

      bc_version2 =
        insert(:business_concept_version,
          business_concept: bc2,
          content: content,
          name: "bc_version2"
        )

      bc_versions =
        [bc_version1, bc_version2]
        |> Enum.map(&Map.take(&1, [:id]))
        |> Enum.map(&CollectionUtils.stringify_keys/1)

      params = %{
        "domain_id" => d3.id,
        "content" => update_content
      }

      assert {:ok, bcv_ids} = BulkUpdate.update_all(claims, bc_versions, params)
      assert length(bcv_ids) == 2

      assert [{:reindex, :concepts, _}, {:reindex, :concepts, _}] = MockIndexWorker.calls()

      assert BusinessConcepts.get_business_concept_version!(Enum.at(bcv_ids, 0)).business_concept.domain_id ==
               d3.id

      assert BusinessConcepts.get_business_concept_version!(Enum.at(bcv_ids, 0)).content == %{
               "Field1" => "First udpate",
               "Field2" => "Second field",
               "Field3" => 3,
               "Field4" => [1, 2],
               "Field5" => %{"foo" => "bar"}
             }

      assert BusinessConcepts.get_business_concept_version!(Enum.at(bcv_ids, 1)).business_concept.domain_id ==
               d3.id

      assert BusinessConcepts.get_business_concept_version!(Enum.at(bcv_ids, 1)).content == %{
               "Field1" => "First udpate",
               "Field2" => "Second field",
               "Field3" => 3,
               "Field4" => [1, 2],
               "Field5" => %{"foo" => "bar"}
             }
    end

    test "update all business concept versions with invalid data: template does not exist" do
      claims = build(:claims)

      d1 = insert(:domain, name: "d1")
      d2 = insert(:domain, name: "d2")
      d3 = insert(:domain, name: "d3")

      bc1 = insert(:business_concept, domain: d1, type: "template_test_x")
      bc2 = insert(:business_concept, domain: d2, type: "template_test_x")

      content = %{
        "Field1" => "First field",
        "Field2" => "Second field"
      }

      update_content = %{
        "Field1" => "First update",
        "Field2" => "Second field"
      }

      bc_version1 = insert(:business_concept_version, business_concept: bc1, content: content)
      bc_version2 = insert(:business_concept_version, business_concept: bc2, content: content)

      bc_versions =
        [bc_version1, bc_version2]
        |> Enum.map(&Map.take(&1, [:id]))
        |> Enum.map(&CollectionUtils.stringify_keys/1)

      params = %{
        "domain_id" => d3.id,
        "content" => update_content
      }

      assert {:error, :template_not_found} = BulkUpdate.update_all(claims, bc_versions, params)
    end

    test "update all business concept versions with invalid data: domain value to update does not exist" do
      claims = build(:claims)

      d1 = insert(:domain, name: "d1")
      d2 = insert(:domain, name: "d2")
      d3 = insert(:domain, name: "d3")

      bc1 = insert(:business_concept, domain: d1, type: "template_test")
      bc2 = insert(:business_concept, domain: d2, type: "template_test")

      content = %{
        "Field1" => "First field",
        "Field2" => "Second field"
      }

      update_content = %{
        "Field1" => "First update",
        "Field2" => "Second field"
      }

      bc_version1 = insert(:business_concept_version, business_concept: bc1, content: content)
      bc_version2 = insert(:business_concept_version, business_concept: bc2, content: content)

      bc_versions =
        [bc_version1, bc_version2]
        |> Enum.map(&Map.take(&1, [:id]))
        |> Enum.map(&CollectionUtils.stringify_keys/1)

      d3 =
        d3
        |> Map.put(:id, 12_345)

      params = %{
        "domain_id" => d3.id,
        "content" => update_content
      }

      assert {:error, :missing_domain} = BulkUpdate.update_all(claims, bc_versions, params)
    end

    test "update all business concept versions with invalid data: name exiting on target domain group" do
      claims = build(:claims)
      group = insert(:domain_group)

      d1 = insert(:domain, name: "d1")
      d2 = insert(:domain, name: "d2")
      d3 = insert(:domain, name: "d3", domain_group: group)

      bc1 = insert(:business_concept, domain: d1, type: "template_test")
      bc2 = insert(:business_concept, domain: d2, type: "template_test")
      bc3 = insert(:business_concept, domain: d3, type: "template_test")

      content = %{
        "Field1" => "First field",
        "Field2" => "Second field"
      }

      update_content = %{
        "Field1" => "First update",
        "Field2" => "Second field"
      }

      bc_version1 =
        insert(:business_concept_version, business_concept: bc1, name: "name", content: content)

      bc_version2 = insert(:business_concept_version, business_concept: bc2, content: content)
      insert(:business_concept_version, business_concept: bc3, name: "name", content: content)

      bc_versions =
        [bc_version1, bc_version2]
        |> Enum.map(&Map.take(&1, [:id]))
        |> Enum.map(&CollectionUtils.stringify_keys/1)

      params = %{
        "domain_id" => d3.id,
        "content" => update_content
      }

      assert {:error, %{errors: [name: error]}} =
               BulkUpdate.update_all(claims, bc_versions, params)

      assert {"error.existing.business_concept.name", []} = error
    end

    test "two versions of the same concept" do
      claims = build(:claims)

      d1 = insert(:domain, name: "d1")
      d3 = insert(:domain, name: "d3")

      concept = insert(:business_concept, domain: d1, type: "template_test")

      content = %{
        "Field1" => "First field",
        "Field2" => "Second field"
      }

      bc_version_draft =
        insert(:business_concept_version, business_concept: concept, content: content)

      bc_version_published =
        insert(:business_concept_version,
          business_concept: concept,
          content: content,
          status: "published"
        )

      bc_versions =
        [bc_version_draft, bc_version_published]
        |> Enum.map(&Map.take(&1, [:id]))
        |> Enum.map(&CollectionUtils.stringify_keys/1)

      update_content = %{
        "Field1" => "First udpate",
        "Field2" => "Second field"
      }

      params = %{
        "domain_id" => d3.id,
        "content" => update_content
      }

      assert {:ok, bcv_ids} = BulkUpdate.update_all(claims, bc_versions, params)
      assert length(bcv_ids) == 2
      assert [{:reindex, :concepts, _}, {:reindex, :concepts, _}] = MockIndexWorker.calls()

      assert BusinessConcepts.get_business_concept_version!(Enum.at(bcv_ids, 0)).business_concept.domain_id ==
               d3.id

      assert BusinessConcepts.get_business_concept_version!(Enum.at(bcv_ids, 0)).content == %{
               "Field1" => "First udpate",
               "Field2" => "Second field"
             }

      assert BusinessConcepts.get_business_concept_version!(Enum.at(bcv_ids, 1)).business_concept.domain_id ==
               d3.id

      assert BusinessConcepts.get_business_concept_version!(Enum.at(bcv_ids, 1)).content == %{
               "Field1" => "First udpate",
               "Field2" => "Second field"
             }
    end

    test "validates only updated fields and gives an error when they arec incorrect" do
      claims = build(:claims)

      d1 = insert(:domain, name: "d1")
      c1 = insert(:business_concept, domain: d1, type: "template_test")
      c2 = insert(:business_concept, domain: d1, type: "template_test")

      content = %{
        "Field1" => "First field",
        "Field2" => "Second field"
      }

      v1 =
        insert(:business_concept_version,
          business_concept: c1,
          content: content,
          status: "published"
        )

      v2 =
        insert(:business_concept_version,
          business_concept: c2,
          content: content,
          status: "draft"
        )

      bc_versions =
        [v1, v2]
        |> Enum.map(&Map.take(&1, [:id]))
        |> Enum.map(&CollectionUtils.stringify_keys/1)

      update_content = %{
        "Field1" => "First udpate",
        "Field2" => "Second field"
      }

      params = %{
        "domain_id" => d1.id,
        "content" => update_content
      }

      assert {:ok, bcv_ids} = BulkUpdate.update_all(claims, bc_versions, params)
      assert length(bcv_ids) == 2

      assert Enum.all?(
               bcv_ids,
               &(BusinessConcepts.get_business_concept_version!(&1).business_concept.domain_id ==
                   d1.id)
             )

      assert Enum.all?(
               bcv_ids,
               &(BusinessConcepts.get_business_concept_version!(&1).content == %{
                   "Field1" => "First udpate",
                   "Field2" => "Second field"
                 })
             )

      update_content = %{
        "Field1" => "First udpate",
        "Field2" => "Second field",
        "Field3" => "Wrong"
      }

      params = %{
        "domain_id" => d1.id,
        "content" => update_content
      }

      assert {:error, changeset} =
               BulkUpdate.update_all(claims, [Enum.at(bc_versions, 0)], params)

      assert %{errors: [Field3: error], valid?: false} = changeset
      assert {"is invalid", [{:validation, :inclusion}, _]} = error

      assert {:ok, bcv_ids} = BulkUpdate.update_all(claims, [Enum.at(bc_versions, 1)], params)
      assert length(bcv_ids) == 1

      assert [
               {:reindex, :concepts, _},
               {:reindex, :concepts, _},
               {:reindex, :concepts, _}
             ] = MockIndexWorker.calls()

      assert Enum.all?(
               bcv_ids,
               &BusinessConcepts.get_business_concept_version!(&1).in_progress
             )
    end
  end
end
