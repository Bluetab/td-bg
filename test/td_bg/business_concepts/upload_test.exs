defmodule TdBg.UploadTest do
  use TdBg.DataCase

  import Mox

  alias TdBg.BusinessConcept.Upload
  alias TdBg.BusinessConcepts
  alias TdCache.HierarchyCache
  alias TdCore.Search.MockIndexWorker

  @default_template %{
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
            "label" => "hierarchy name 1",
            "values" => %{"hierarchy" => %{"id" => 1}}
          },
          %{
            "name" => "hierarchy_name_2",
            "label" => "hierarchy name 2",
            "type" => "hierarchy",
            "cardinality" => "*",
            "values" => %{"hierarchy" => %{"id" => 1}}
          }
        ]
      }
    ],
    scope: "test",
    label: "term",
    id: "999"
  }

  @i18n_template %{
    name: "i18n",
    content: [
      %{
        "name" => "group",
        "fields" => [
          %{
            "cardinality" => "?",
            "label" => "i18n_test.Dropdown Fixed",
            "name" => "i18n_test.dropdown",
            "type" => "string",
            "values" => %{"fixed" => ["pear", "banana", "apple"]},
            "widget" => "dropdown"
          },
          %{
            "cardinality" => "?",
            "label" => "i18n_test.no_translate",
            "name" => "i18n_test.no_translate",
            "type" => "string",
            "values" => nil,
            "widget" => "string"
          },
          %{
            "cardinality" => "?",
            "label" => "i18n_test.Radio Fixed",
            "name" => "i18n_test.radio",
            "type" => "string",
            "values" => %{"fixed" => ["pear", "banana", "apple"]},
            "widget" => "radio"
          },
          %{
            "cardinality" => "*",
            "label" => "i18n_test.Checkbox Fixed",
            "name" => "i18n_test.checkbox",
            "type" => "string",
            "values" => %{"fixed" => ["pear", "banana", "apple"]},
            "widget" => "checkbox"
          }
        ]
      }
    ],
    scope: "test",
    label: "i18n",
    id: "1"
  }
  @default_lang "en"

  setup_all do
    start_supervised!(TdBg.Cache.ConceptLoader)
    start_supervised!(TdCore.Search.Cluster)
    start_supervised!(TdCore.Search.IndexWorker)
    :ok
  end

  setup :verify_on_exit!

  setup _context do
    %{id: template_id} = template = Templates.create_template(@default_template)
    %{id: i18n_template_id} = i18n_template = Templates.create_template(@i18n_template)

    %{id: hierarchy_id} = hierarchy = create_hierarchy()
    HierarchyCache.put(hierarchy)

    on_exit(fn ->
      MockIndexWorker.clear()
      Templates.delete(template_id)
      Templates.delete(i18n_template_id)
      HierarchyCache.delete(hierarchy_id)
    end)

    [template: template, i18n_template: i18n_template, hierarchy: hierarchy]
  end

  describe "business_concept_upload" do
    setup [:set_mox_from_context, :insert_i18n_messages]

    test "from_csv/4 uploads business concept versions with valid data" do
      claims = build(:claims)
      insert(:domain, external_id: "domain")
      business_concept_upload = %{path: "test/fixtures/upload.csv"}

      assert {:ok, [concept_id | _]} =
               Upload.from_csv(
                 business_concept_upload,
                 claims,
                 fn _, _ -> true end,
                 @default_lang
               )

      version = BusinessConcepts.get_last_version_by_business_concept_id!(concept_id)
      assert MockIndexWorker.calls() == [{:reindex, :concepts, [concept_id]}]
      concept = Map.get(version, :business_concept)
      assert Map.get(concept, :confidential)
      assert version |> Map.get(:content) |> Map.get("role") == ["Role"]
    end

    test "from_csv/4 uploads business concept versions with hierarchy data" do
      claims = build(:claims)
      insert(:domain, external_id: "domain")
      business_concept_upload = %{path: "test/fixtures/upload_hierarchy.csv"}

      assert {:ok, [concept_id | _]} =
               Upload.from_csv(
                 business_concept_upload,
                 claims,
                 fn _, _ -> true end,
                 @default_lang
               )

      assert MockIndexWorker.calls() == [{:reindex, :concepts, [concept_id]}]
      version = BusinessConcepts.get_last_version_by_business_concept_id!(concept_id)

      assert %{
               "hierarchy_name_1" => "1_2",
               "hierarchy_name_2" => ["1_2", "1_1"]
             } = Map.get(version, :content)
    end

    test "from_csv/4 get error business concept versions with invalid hierarchy data" do
      claims = build(:claims)
      insert(:domain, external_id: "domain")
      business_concept_upload = %{path: "test/fixtures/upload_invalid_hierarchy.csv"}

      assert {:error, changeset} =
               Upload.from_csv(
                 business_concept_upload,
                 claims,
                 fn _, _ -> true end,
                 @default_lang
               )

      assert [
               hierarchy_name_1: {"has more than one node children_2"},
               hierarchy_name_2: {"has more than one node children_2"}
             ] =
               changeset
               |> Map.get(:errors)
    end

    test "from_csv/4 uploads business concept with translation" do
      claims = build(:claims)
      insert(:domain, external_id: "domain")
      business_concept_upload = %{path: "test/fixtures/upload_translation.csv"}

      assert {:ok, [concept_id | _]} =
               Upload.from_csv(business_concept_upload, claims, fn _, _ -> true end, "es")

      version = BusinessConcepts.get_last_version_by_business_concept_id!(concept_id)
      assert MockIndexWorker.calls() == [{:reindex, :concepts, [concept_id]}]

      assert %{
               "i18n_test.checkbox" => ["apple", "pear"],
               "i18n_test.dropdown" => "pear",
               "i18n_test.radio" => "banana",
               "i18n_test.no_translate" => "NO TRANSLATION"
             } = Map.get(version, :content)
    end

    test "from_csv/4 returns error on invalid content" do
      claims = build(:claims)
      insert(:domain, external_id: "domain")
      business_concept_upload = %{path: "test/fixtures/incorrect_upload.csv"}

      assert {:error, changeset} =
               Upload.from_csv(
                 business_concept_upload,
                 claims,
                 fn _, _ -> true end,
                 @default_lang
               )

      message =
        changeset
        |> Map.get(:errors)
        |> Keyword.get(:critical)
        |> elem(0)

      assert message == "is invalid"
    end

    test "from_csv/4 Does not upload business concept versions without permissions" do
      claims = build(:claims)
      insert(:domain, external_id: "domain", name: "fobidden_domain")
      business_concept_upload = %{path: "test/fixtures/upload.csv"}

      assert {:error, %{error: :forbidden, domain: "fobidden_domain"}} =
               Upload.from_csv(
                 business_concept_upload,
                 claims,
                 fn _, _ -> false end,
                 @default_lang
               )
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

  defp insert_i18n_messages(_) do
    CacheHelpers.put_i18n_messages("es", [
      %{message_id: "fields.i18n_test.Dropdown Fixed", definition: "Dropdown Fijo"},
      %{message_id: "fields.i18n_test.Dropdown Fixed.pear", definition: "pera"},
      %{message_id: "fields.i18n_test.Dropdown Fixed.banana", definition: "plátano"},
      %{message_id: "fields.i18n_test.Dropdown Fixed.apple", definition: "manzana"},
      %{message_id: "fields.i18n_test.Radio Fixed", definition: "Radio Fijo"},
      %{message_id: "fields.i18n_test.Radio Fixed.pear", definition: "pera"},
      %{message_id: "fields.i18n_test.Radio Fixed.banana", definition: "plátano"},
      %{message_id: "fields.i18n_test.Radio Fixed.apple", definition: "manzana"},
      %{message_id: "fields.i18n_test.Checkbox Fixed", definition: "Checkbox Fijo"},
      %{message_id: "fields.i18n_test.Checkbox Fixed.pear", definition: "pera"},
      %{message_id: "fields.i18n_test.Checkbox Fixed.banana", definition: "plátano"},
      %{message_id: "fields.i18n_test.Checkbox Fixed.apple", definition: "manzana"}
    ])
  end
end
