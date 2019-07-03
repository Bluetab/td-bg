defmodule TdBg.BusinessConceptBulkUpdateTest do
  use TdBg.DataCase

  alias TdBg.BusinessConcept.BulkUpdate
  alias TdBg.BusinessConcepts
  alias TdBg.BusinessConcepts.BusinessConcept
  alias TdBg.Utils.CollectionUtils
  alias TdBgWeb.ApiServices.MockTdAuthService
  alias TdCache.TemplateCache

  setup_all do
    start_supervised(MockTdAuthService)
    :ok
  end

  describe "business_concepts_bulk_update" do
    test "update_all/3 update all business concept versions with valid data" do
      user = build(:user)

      d1 = insert(:domain, name: "d1")
      d2 = insert(:domain, name: "d2")
      d3 = insert(:domain, name: "d3")

      TemplateCache.put(%{
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

    test "update_all/3 update all business concept versions with invalid data: different templates (case A)" do
      user = build(:user)

      d1 = insert(:domain, name: "d1")
      d2 = insert(:domain, name: "d2")
      d3 = insert(:domain, name: "d3")

      TemplateCache.put(%{
        name: "template_test1",
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
        label: "template_label1",
        id: "999"
      })

      TemplateCache.put(%{
        name: "template_test2",
        content: [
          %{
            "name" => "Field3",
            "type" => "string",
            "group" => "Multiple Group",
            "label" => "Multiple 1",
            "values" => nil,
            "cardinality" => "1"
          }
        ],
        scope: "test",
        label: "template_label2",
        id: "1000"
      })

      # the insert order will determine the template which will be taken (see next test)
      bc1 = insert(:business_concept, domain: d1, type: "template_test1")
      bc2 = insert(:business_concept, domain: d2, type: "template_test2")

      content1 = %{
        "Field1" => "First field",
        "Field2" => "Second field"
      }

      content2 = %{
        "Field3" => "Third field"
      }

      update_content = %{
        "Field1" => "First update",
        "Field2" => "Second update"
      }

      bc_version1 = insert(:business_concept_version, business_concept: bc1, content: content1)
      bc_version2 = insert(:business_concept_version, business_concept: bc2, content: content2)

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

      assert Enum.at(bcv_ids, 0) == bc_version2.id

      assert BusinessConcepts.get_business_concept_version!(bc_version2.id).business_concept.domain_id ==
               d3.id

      assert BusinessConcepts.get_business_concept_version!(bc_version2.id).business_concept.type ==
               "template_test2"

      assert BusinessConcepts.get_business_concept_version!(bc_version2.id).content == %{
               "Field1" => "First update",
               "Field2" => "Second update"
             }

      assert Enum.at(bcv_ids, 1) == bc_version1.id

      assert BusinessConcepts.get_business_concept_version!(bc_version1.id).business_concept.domain_id ==
               d3.id

      assert BusinessConcepts.get_business_concept_version!(bc_version1.id).business_concept.type ==
               "template_test1"

      assert BusinessConcepts.get_business_concept_version!(bc_version1.id).content == %{
               "Field1" => "First update",
               "Field2" => "Second update"
             }
    end

    test "update_all/3 update all business concept versions with invalid data: different templates (case B)" do
      user = build(:user)

      d1 = insert(:domain, name: "d1")
      d2 = insert(:domain, name: "d2")
      d3 = insert(:domain, name: "d3")

      TemplateCache.put(%{
        name: "template_test1",
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
        label: "template_label1",
        id: "999"
      })

      TemplateCache.put(%{
        name: "template_test2",
        content: [
          %{
            "name" => "Field3",
            "type" => "string",
            "group" => "Multiple Group",
            "label" => "Multiple 1",
            "values" => nil,
            "cardinality" => "1"
          }
        ],
        scope: "test",
        label: "template_label2",
        id: "1000"
      })

      # the insert order will determine the template which will be taken (see previous test)
      bc2 = insert(:business_concept, domain: d2, type: "template_test2")
      bc1 = insert(:business_concept, domain: d1, type: "template_test1")

      content1 = %{
        "Field1" => "First field",
        "Field2" => "Second field"
      }

      content2 = %{
        "Field3" => "Third field"
      }

      update_content = %{
        "Field1" => "First update",
        "Field2" => "Second update"
      }

      bc_version1 = insert(:business_concept_version, business_concept: bc1, content: content1)
      bc_version2 = insert(:business_concept_version, business_concept: bc2, content: content2)

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

      assert Enum.at(bcv_ids, 0) == bc_version1.id

      assert BusinessConcepts.get_business_concept_version!(bc_version1.id).business_concept.domain_id ==
               d3.id

      assert BusinessConcepts.get_business_concept_version!(bc_version1.id).business_concept.type ==
               "template_test1"

      assert BusinessConcepts.get_business_concept_version!(bc_version1.id).content == %{}

      assert Enum.at(bcv_ids, 1) == bc_version2.id

      assert BusinessConcepts.get_business_concept_version!(bc_version2.id).business_concept.domain_id ==
               d3.id

      assert BusinessConcepts.get_business_concept_version!(bc_version2.id).business_concept.type ==
               "template_test2"

      assert BusinessConcepts.get_business_concept_version!(bc_version2.id).content == %{
               "Field3" => "Third field"
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

      TemplateCache.put(%{
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

      TemplateCache.put(%{
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
