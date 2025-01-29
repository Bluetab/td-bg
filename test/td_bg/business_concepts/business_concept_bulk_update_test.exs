defmodule TdBg.BusinessConceptBulkUpdateTest do
  use TdBg.DataCase

  import Mox

  alias TdBg.BusinessConcept.BulkUpdate
  alias TdBg.BusinessConcepts
  alias TdCore.Search.IndexWorkerMock
  alias TdCore.Utils.CollectionUtils

  setup_all do
    start_supervised!(TdBg.Cache.ConceptLoader)

    :ok
  end

  setup _context do
    Templates.create_template(%{
      name: "template_test",
      content: [
        build(:template_group,
          name: "group",
          fields: [
            build(:template_field,
              name: "Field1",
              type: "string",
              group: "Multiple Group",
              label: "Field 1",
              values: nil,
              cardinality: "1"
            ),
            build(:template_field,
              name: "Field2",
              type: "string",
              group: "Multiple Group",
              label: "Field 2",
              values: nil,
              cardinality: "1"
            ),
            build(:template_field,
              name: "Field3",
              type: "string",
              group: "Multiple Group",
              label: "Field 3",
              default: 1,
              values: %{fixed: ["1", "2", "3"]},
              cardinality: "1"
            ),
            build(:template_field,
              name: "Field4",
              type: "string",
              group: "Multiple Group",
              label: "Field 4",
              values: %{fixed: ["1", "2", "3"]},
              cardinality: "*"
            ),
            build(:template_field,
              name: "Field5",
              type: "enriched_text",
              group: "Multiple Group",
              label: "Field 5",
              cardinality: "*"
            ),
            build(:template_field,
              cardinality: "*",
              default: %{origin: "default", value: ""},
              label: "Field 6",
              name: "Field6",
              type: "url",
              widget: "pair_list",
              values: nil
            )
          ]
        )
      ],
      scope: "test",
      label: "template_label",
      id: "999"
    })

    on_exit(fn ->
      IndexWorkerMock.clear()
    end)

    :ok
  end

  setup :verify_on_exit!

  describe "BulkUpdate.update_all/3" do
    setup :set_mox_from_context

    test "update all business concept versions with valid data" do
      IndexWorkerMock.clear()
      claims = build(:claims)

      d1 = insert(:domain, name: "d1")
      d2 = insert(:domain, name: "d2")
      d3 = insert(:domain, name: "d3")

      bc1 = insert(:business_concept, domain: d1, type: "template_test")
      bc2 = insert(:business_concept, domain: d2, type: "template_test")

      content = %{
        "Field1" => %{"value" => "First field", "origin" => "user"},
        "Field2" => %{"value" => "Second field", "origin" => "user"},
        "Field3" => %{"value" => "3", "origin" => "user"},
        "Field4" => %{"value" => ["1", "2"], "origin" => "user"},
        "Field5" => %{"value" => "foo", "origin" => "user"},
        "Field6" => %{
          "value" => [
            %{"url_name" => "com", "url_value" => "www.com.com"},
            %{"url_name" => "", "url_value" => "www.net.net"},
            %{"url_name" => "org", "url_value" => "www.org.org"}
          ],
          "origin" => "user"
        }
      }

      update_content = %{
        "Field1" => %{"value" => "First udpate", "origin" => "user"},
        "Field2" => %{"value" => "Second field", "origin" => "user"},
        "Field3" => %{"value" => "1", "origin" => "user"},
        "Field4" => %{"value" => [], "origin" => "user"},
        "Field5" => %{"value" => "foo", "origin" => "user"},
        "Field6" => %{
          "value" => [
            %{"url_name" => "com updated", "url_value" => "www.com.com"},
            %{"url_name" => "net updated", "url_value" => "www.net.net"},
            %{"url_name" => "", "url_value" => "www.org.org"}
          ],
          "origin" => "user"
        }
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

      assert [{:reindex, :concepts, _}, {:reindex, :concepts, _}] = IndexWorkerMock.calls()

      assert BusinessConcepts.get_business_concept_version!(Enum.at(bcv_ids, 0)).business_concept.domain_id ==
               d3.id

      assert BusinessConcepts.get_business_concept_version!(Enum.at(bcv_ids, 0)).content == %{
               "Field1" => %{"value" => "First udpate", "origin" => "user"},
               "Field2" => %{"value" => "Second field", "origin" => "user"},
               "Field3" => %{"value" => "1", "origin" => "user"},
               "Field4" => %{"value" => [""], "origin" => "default"},
               "Field5" => %{"value" => enrich_text("foo"), "origin" => "user"},
               "Field6" => %{
                 "value" => [
                   %{"url_name" => "com updated", "url_value" => "www.com.com"},
                   %{"url_name" => "net updated", "url_value" => "www.net.net"},
                   %{"url_name" => "", "url_value" => "www.org.org"}
                 ],
                 "origin" => "user"
               }
             }

      assert BusinessConcepts.get_business_concept_version!(Enum.at(bcv_ids, 1)).business_concept.domain_id ==
               d3.id

      assert BusinessConcepts.get_business_concept_version!(Enum.at(bcv_ids, 1)).content == %{
               "Field1" => %{"value" => "First udpate", "origin" => "user"},
               "Field2" => %{"value" => "Second field", "origin" => "user"},
               "Field3" => %{"value" => "1", "origin" => "user"},
               "Field4" => %{"value" => [""], "origin" => "default"},
               "Field5" => %{"value" => enrich_text("foo"), "origin" => "user"},
               "Field6" => %{
                 "value" => [
                   %{"url_name" => "com updated", "url_value" => "www.com.com"},
                   %{"url_name" => "net updated", "url_value" => "www.net.net"},
                   %{"url_name" => "", "url_value" => "www.org.org"}
                 ],
                 "origin" => "user"
               }
             }

      IndexWorkerMock.clear()
    end

    test "update all business concept versions with invalid data: template does not exist" do
      claims = build(:claims)

      d1 = insert(:domain, name: "d1")
      d2 = insert(:domain, name: "d2")
      d3 = insert(:domain, name: "d3")

      bc1 = insert(:business_concept, domain: d1, type: "template_test_x")
      bc2 = insert(:business_concept, domain: d2, type: "template_test_x")

      content = %{
        "Field1" => %{"value" => "First field", "origin" => "user"},
        "Field2" => %{"value" => "Second field", "origin" => "user"},
        "Field3" => %{"value" => "1", "origin" => "user"}
      }

      update_content = %{
        "Field1" => %{"value" => "First update", "origin" => "user"},
        "Field2" => %{"value" => "Second field", "origin" => "user"},
        "Field3" => %{"value" => "1", "origin" => "user"}
      }

      bc_version1 = insert(:business_concept_version, business_concept: bc1, content: content)
      bc_version2 = insert(:business_concept_version, business_concept: bc2, content: content)

      bc_versions =
        [bc_version1, bc_version2]
        |> Enum.map(&Map.take(&1, [:id, :business_concept]))
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
        "Field1" => %{"value" => "First field", "origin" => "user"},
        "Field2" => %{"value" => "Second field", "origin" => "user"}
      }

      update_content = %{
        "Field1" => %{"value" => "First update", "origin" => "user"},
        "Field2" => %{"value" => "Second field", "origin" => "user"}
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
        "Field1" => %{"value" => "First field", "origin" => "user"},
        "Field2" => %{"value" => "Second field", "origin" => "user"},
        "Field3" => %{"value" => 1, "origin" => "user"}
      }

      update_content = %{
        "Field1" => %{"value" => "First update", "origin" => "user"},
        "Field2" => %{"value" => "Second field", "origin" => "user"},
        "Field3" => %{"value" => "1", "origin" => "user"}
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
      IndexWorkerMock.clear()
      claims = build(:claims)

      d1 = insert(:domain, name: "d1")
      d3 = insert(:domain, name: "d3")

      concept = insert(:business_concept, domain: d1, type: "template_test")

      content = %{
        "Field1" => %{"value" => "First field", "origin" => "user"},
        "Field2" => %{"value" => "Second field", "origin" => "user"}
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
        "Field1" => %{"value" => "First udpate", "origin" => "user"},
        "Field2" => %{"value" => "Second field", "origin" => "user"},
        "Field3" => %{"value" => "1", "origin" => "user"}
      }

      params = %{
        "domain_id" => d3.id,
        "content" => update_content
      }

      assert {:ok, bcv_ids} = BulkUpdate.update_all(claims, bc_versions, params)
      assert length(bcv_ids) == 2
      assert [{:reindex, :concepts, _}, {:reindex, :concepts, _}] = IndexWorkerMock.calls()

      assert BusinessConcepts.get_business_concept_version!(Enum.at(bcv_ids, 0)).business_concept.domain_id ==
               d3.id

      assert BusinessConcepts.get_business_concept_version!(Enum.at(bcv_ids, 0)).content == %{
               "Field1" => %{"value" => "First udpate", "origin" => "user"},
               "Field2" => %{"value" => "Second field", "origin" => "user"},
               "Field3" => %{"value" => "1", "origin" => "user"}
             }

      assert BusinessConcepts.get_business_concept_version!(Enum.at(bcv_ids, 1)).business_concept.domain_id ==
               d3.id

      assert BusinessConcepts.get_business_concept_version!(Enum.at(bcv_ids, 1)).content == %{
               "Field1" => %{"value" => "First udpate", "origin" => "user"},
               "Field2" => %{"value" => "Second field", "origin" => "user"},
               "Field3" => %{"value" => "1", "origin" => "user"}
             }
    end

    test "validates only updated fields and gives an error when they are incorrect" do
      claims = build(:claims)

      d1 = insert(:domain, name: "d1")
      c1 = insert(:business_concept, domain: d1, type: "template_test")
      c2 = insert(:business_concept, domain: d1, type: "template_test")

      content = %{
        "Field1" => %{"value" => "First field", "origin" => "user"},
        "Field2" => %{"value" => "Second field", "origin" => "user"},
        "Field3" => %{"value" => "1", "origin" => "user"}
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
        "Field1" => %{"value" => "First udpate", "origin" => "user"},
        "Field2" => %{"value" => "Second field", "origin" => "user"},
        "Field3" => %{"value" => "1", "origin" => "user"}
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
                   "Field1" => %{"value" => "First udpate", "origin" => "user"},
                   "Field2" => %{"value" => "Second field", "origin" => "user"},
                   "Field3" => %{"value" => "1", "origin" => "user"}
                 })
             )

      update_content = %{
        "Field1" => %{"value" => "First udpate", "origin" => "user"},
        "Field2" => %{"value" => "Second field", "origin" => "user"},
        "Field3" => %{"value" => "Wrong", "origin" => "user"}
      }

      params = %{
        "domain_id" => d1.id,
        "content" => update_content
      }

      assert {:error, changeset} =
               BulkUpdate.update_all(claims, [Enum.at(bc_versions, 0)], params)

      assert %{errors: [content: {"Field3: is invalid", _}], valid?: false} = changeset
    end
  end

  defp enrich_text(text) do
    [
      %{
        "document" => %{
          "nodes" => [
            %{
              "nodes" => [%{"leaves" => [%{"text" => "#{text}"}], "object" => "text"}],
              "object" => "block",
              "type" => "paragraph"
            }
          ]
        }
      }
    ]
  end
end
