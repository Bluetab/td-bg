defmodule TdBg.BusinessConceptBulkUpdateTest do
  use TdBg.DataCase

  alias TdBg.BusinessConcept.BulkUpdate
  alias TdBg.BusinessConcepts
  alias TdBg.BusinessConcepts.BusinessConcept
  alias TdBg.Cache.ConceptLoader
  alias TdBg.Search.IndexWorker
  alias TdBg.Utils.CollectionUtils
  alias TdBgWeb.ApiServices.MockTdAuthService

  setup_all do
    start_supervised(ConceptLoader)
    start_supervised(IndexWorker)
    start_supervised(MockTdAuthService)
    :ok
  end

  describe "business_concepts_bulk_update" do
    test "update_all/3 update all business concept versions with valid data" do
      user = build(:user)

      d1 = insert(:domain, name: "d1")
      d2 = insert(:domain, name: "d2")
      d3 = insert(:domain, name: "d3")

      Templates.create_template(%{
        name: "template_test",
        content: [
          %{
            "name" => "Field1",
            "type" => "string",
            "group" => "Multiple Group",
            "label" => "Multiple 1",
            "values" => nil,
            "cardinality" => "1"
          },
          %{
            "name" => "Field2",
            "type" => "string",
            "group" => "Multiple Group",
            "label" => "Multiple 1",
            "values" => nil,
            "cardinality" => "1"
          }
        ],
        scope: "test",
        label: "template_label",
        id: "999"
      })

      bc1 = insert(:business_concept, domain: d1, type: "template_test")
      bc2 = insert(:business_concept, domain: d2, type: "template_test")

      content = %{
        "Field1" => "First field",
        "Field2" => "Second field"
      }

      update_content = %{
        "Field1" => "First udpate",
        "Field2" => "Second field"
      }

      bc_version1 = insert(:business_concept_version, business_concept: bc1, content: content)
      bc_version2 = insert(:business_concept_version, business_concept: bc2, content: content)

      bc_versions =
        [bc_version1, bc_version2]
        |> Enum.map(&Map.take(&1, [:id]))
        |> Enum.map(&CollectionUtils.stringify_keys(&1))

      params = %{
        "domain_id" => d3.id,
        "content" => update_content
      }

      assert {:ok, bcv_ids} = BulkUpdate.update_all(user, bc_versions, params)
      assert length(bcv_ids) == 2

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

    test "update_all/3 update all business concept versions with invalid data: template does not exist" do
      user = build(:user)

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
        |> Enum.map(&CollectionUtils.stringify_keys(&1))

      params = %{
        "domain_id" => d3.id,
        "content" => update_content
      }

      assert {:error, :template_not_found} = BulkUpdate.update_all(user, bc_versions, params)
    end

    test "update_all/3 update all business concept versions with invalid data: domain value to update does not exist" do
      user = build(:user)

      d1 = insert(:domain, name: "d1")
      d2 = insert(:domain, name: "d2")
      d3 = insert(:domain, name: "d3")

      Templates.create_template(%{
        name: "template_test",
        content: [
          %{
            "name" => "Field1",
            "type" => "string",
            "group" => "Multiple Group",
            "label" => "Multiple 1",
            "values" => nil,
            "cardinality" => "1"
          },
          %{
            "name" => "Field2",
            "type" => "string",
            "group" => "Multiple Group",
            "label" => "Multiple 1",
            "values" => nil,
            "cardinality" => "1"
          }
        ],
        scope: "test",
        label: "template_label",
        id: "999"
      })

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
        |> Enum.map(&CollectionUtils.stringify_keys(&1))

      d3 =
        d3
        |> Map.put(:id, 12_345)

      params = %{
        "domain_id" => d3.id,
        "content" => update_content
      }

      assert {:error, :missing_domain} = BulkUpdate.update_all(user, bc_versions, params)
    end

    test "update_all/3 two versions of the same concept" do
      user = build(:user)

      d1 = insert(:domain, name: "d1")
      d3 = insert(:domain, name: "d3")

      Templates.create_template(%{
        name: "template_test",
        content: [
          %{
            "name" => "Field1",
            "type" => "string",
            "group" => "Multiple Group",
            "label" => "Multiple 1",
            "values" => nil,
            "cardinality" => "1"
          },
          %{
            "name" => "Field2",
            "type" => "string",
            "group" => "Multiple Group",
            "label" => "Multiple 1",
            "values" => nil,
            "cardinality" => "1"
          }
        ],
        scope: "test",
        label: "template_label",
        id: "999"
      })

      concept = insert(:business_concept, domain: d1, type: "template_test")

      content = %{
        "Field1" => "First field",
        "Field2" => "Second field"
      }

      bc_version_draft =
        insert(:business_concept_version, business_concept: concept, content: content)

      bc_version_published =
        insert(:business_concept_version, business_concept: concept, content: content)

      attrs = %{status: BusinessConcept.status().published}

      {:ok, bc_version_published} =
        BusinessConcepts.update_business_concept_version_status(
          bc_version_published,
          attrs
        )

      bc_versions =
        [bc_version_draft, bc_version_published]
        |> Enum.map(&Map.take(&1, [:id]))
        |> Enum.map(&CollectionUtils.stringify_keys(&1))

      update_content = %{
        "Field1" => "First udpate",
        "Field2" => "Second field"
      }

      params = %{
        "domain_id" => d3.id,
        "content" => update_content
      }

      assert {:ok, bcv_ids} = BulkUpdate.update_all(user, bc_versions, params)
      assert length(bcv_ids) == 2

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
  end
end
