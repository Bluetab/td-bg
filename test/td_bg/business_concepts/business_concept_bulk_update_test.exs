defmodule TdBg.BusinessConceptBulkUpdateTest do
  use TdBg.DataCase

  alias TdBg.BusinessConcept.BulkUpdate
  alias TdBg.Utils.CollectionUtils
  alias TdBgWeb.ApiServices.MockTdAuthService
  alias TdPerms.MockDynamicFormCache

  setup_all do
    start_supervised(MockTdAuthService)
    start_supervised(MockDynamicFormCache)
    :ok
  end

  describe "business_concepts_bulk_update" do
    test "update_all/3 update all business concept versions with valid data" do
      user = build(:user)

      d1 = insert(:domain, name: "d1")
      d2 = insert(:domain, name: "d2")
      d3 = insert(:domain, name: "d3")

      MockDynamicFormCache.put_template(%{
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

      IO.inspect(BulkUpdate.update_all(user, bc_versions, params))
    end
  end
end
