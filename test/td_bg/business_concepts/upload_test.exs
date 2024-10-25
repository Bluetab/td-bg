defmodule TdBg.UploadTest do
  use TdBg.DataCase

  import Mox

  alias TdBg.BusinessConcept.Upload
  alias TdBg.BusinessConcepts
  alias TdBg.BusinessConcepts.BusinessConceptVersion
  alias TdBgWeb.Authentication
  alias TdCache.HierarchyCache
  alias TdCore.Search.IndexWorker

  @default_template %{
    name: "term",
    content: [
      %{
        "name" => "group",
        "fields" => [
          %{
            "cardinality" => "1",
            "default" => %{"value" => "", "origin" => "default"},
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
            "cardinality" => "+",
            "description" => "description",
            "label" => "Description",
            "name" => "description",
            "type" => "string"
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
          },
          %{
            "cardinality" => "?",
            "default" => %{"value" => "", "origin" => "default"},
            "description" => "Input your integer",
            "label" => "Number",
            "name" => "input_integer",
            "type" => "integer",
            "widget" => "number",
            "values" => nil
          },
          %{
            "cardinality" => "?",
            "default" => %{"value" => "", "origin" => "default"},
            "description" => "Input your float",
            "label" => "Number",
            "name" => "input_float",
            "type" => "float",
            "widget" => "number",
            "values" => nil
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

  @concept_template %{
    name: "Business Term",
    content: [
      %{
        "name" => "group",
        "fields" => [
          %{
            "cardinality" => "?",
            "label" => "Description",
            "name" => "df_description",
            "type" => "string"
          },
          %{
            "cardinality" => "?",
            "label" => "GDRP",
            "name" => "GDRP",
            "values" => %{"fixed" => ["No", "Sí"]},
            "type" => "string"
          }
        ]
      }
    ],
    scope: "test",
    label: "concept_term",
    id: "2"
  }

  @concept_user_group_validation %{
    name: "User and group validation",
    content: [
      %{
        "name" => "group",
        "fields" => [
          %{
            "cardinality" => "?",
            "default" => %{"value" => "", "origin" => "user"},
            "label" => "List of users/groups",
            "name" => "data_owner",
            "type" => "user_group",
            "values" => %{"processed_users" => [], "role_groups" => "Data Owner"},
            "widget" => "dropdown"
          }
        ]
      }
    ],
    scope: "test",
    label: "user_group_validation",
    id: "3"
  }

  @concept_multiple_user_group_validation %{
    name: "Multiple User Group validation",
    content: [
      %{
        "name" => "group",
        "fields" => [
          %{
            "cardinality" => "*",
            "default" => %{"value" => "", "origin" => "user"},
            "label" => "List of users/groups",
            "name" => "data_owner",
            "type" => "user_group",
            "values" => %{"processed_users" => [], "role_groups" => "Data Owner"},
            "widget" => "dropdown"
          },
          %{
            "name" => "multiple_values",
            "type" => "string",
            "label" => "Multiple values",
            "values" => %{"fixed" => ["v-1", "v-2", "v-3"]},
            "widget" => "checkbox",
            "cardinality" => "*"
          }
        ]
      }
    ],
    scope: "test",
    label: "multiple_user_group_validation",
    id: "4"
  }

  @concept_multiple_cardinality_validation %{
    name: "Multiple cardinality validation",
    content: [
      %{
        "name" => "group",
        "fields" => [
          %{
            "name" => "hierarchy_name",
            "label" => "hierarchy name",
            "type" => "hierarchy",
            "cardinality" => "+",
            "values" => %{"hierarchy" => %{"id" => 1}}
          },
          %{
            "name" => "multiple_values",
            "type" => "string",
            "label" => "Multiple values",
            "values" => %{"fixed" => ["v-1", "v-2", "v-3"]},
            "widget" => "checkbox",
            "cardinality" => "+"
          }
        ]
      }
    ],
    scope: "test",
    label: "multiple_cardinality_validation",
    id: "5"
  }

  @concept_table_validation %{
    name: "Table Template",
    content: [
      %{
        "name" => "group",
        "fields" => [
          %{
            "name" => "Table Field",
            "label" => "Table Field",
            "type" => "table",
            "cardinality" => "*",
            "values" => %{
              "table_columns" => [
                %{"mandatory" => true, "name" => "First Column"},
                %{"mandatory" => true, "name" => "Second Column"}
              ]
            }
          },
          %{
            "name" => "Multiple values",
            "type" => "string",
            "label" => "Multiple values",
            "values" => %{"fixed" => ["v-1", "v-2", "v-3"]},
            "widget" => "checkbox",
            "cardinality" => "*"
          }
        ]
      }
    ],
    scope: "test",
    label: "table_template",
    id: "6"
  }

  @default_lang "en"

  setup_all do
    start_supervised!(TdBg.Cache.ConceptLoader)
    :ok
  end

  setup _context do
    %{id: template_id} = template = Templates.create_template(@default_template)
    %{id: i18n_template_id} = i18n_template = Templates.create_template(@i18n_template)
    %{id: concept_template_id} = concept_template = Templates.create_template(@concept_template)

    %{id: user_group_template_id} =
      user_group_template = Templates.create_template(@concept_user_group_validation)

    %{id: multiple_user_group_template_id} =
      Templates.create_template(@concept_multiple_user_group_validation)

    %{id: multiple_cardinality_template_id} =
      Templates.create_template(@concept_multiple_cardinality_validation)

    %{id: table_template_id} = Templates.create_template(@concept_table_validation)

    %{id: hierarchy_id} = hierarchy = create_hierarchy()
    HierarchyCache.put(hierarchy)

    on_exit(fn ->
      IndexWorker.clear()
      Templates.delete(template_id)
      Templates.delete(i18n_template_id)
      Templates.delete(concept_template_id)
      Templates.delete(user_group_template_id)
      Templates.delete(multiple_user_group_template_id)
      Templates.delete(multiple_cardinality_template_id)
      Templates.delete(table_template_id)
      HierarchyCache.delete(hierarchy_id)
    end)

    [
      template: template,
      i18n_template: i18n_template,
      concept_template: concept_template,
      user_group_template: user_group_template,
      hierarchy: hierarchy
    ]
  end

  setup :verify_on_exit!

  describe "business_concept_upload" do
    setup [:set_mox_from_context, :insert_i18n_messages]

    test "bulk_upload/3 uploads business concept versions as admin with valid data" do
      IndexWorker.clear()
      claims = build(:claims, role: "admin")

      insert(:domain, external_id: "domain")
      business_concept_upload = %{path: "test/fixtures/upload.xlsx"}

      assert %{created: [concept_id], updated: _, errors: _} =
               Upload.bulk_upload(
                 business_concept_upload,
                 claims,
                 lang: @default_lang
               )

      version = BusinessConcepts.get_business_concept_version!(concept_id)
      assert IndexWorker.calls() == [{:reindex, :concepts, [version.business_concept.id]}]

      concept = Map.get(version, :business_concept)
      assert Map.get(concept, :confidential)

      assert Map.get(version, :content) == %{
               "critical" => %{"origin" => "file", "value" => "Yes"},
               "description" => %{"origin" => "file", "value" => ["Test"]},
               "input_float" => %{"origin" => "file", "value" => 12.5},
               "input_integer" => %{"origin" => "file", "value" => 12},
               "role" => %{"origin" => "file", "value" => ["Role"]}
             }
    end

    test "bulk_upload/3 returns error under invalid number" do
      IndexWorker.clear()
      claims = build(:claims, role: "admin")

      insert(:domain, external_id: "domain")
      business_concept_upload = %{path: "test/fixtures/upload_invalid_number.xlsx"}

      assert %{errors: errors} =
               Upload.bulk_upload(
                 business_concept_upload,
                 claims,
                 lang: @default_lang
               )

      assert hd(errors).error_type == "field_error"
    end

    test "bulk_upload/3 returns error under user/group invalid role" do
      IndexWorker.clear()
      claims = build(:claims, role: "admin")
      domain = CacheHelpers.insert_domain(external_id: "domain")
      user = CacheHelpers.insert_user(full_name: "user")
      group = CacheHelpers.insert_group(name: "group")
      CacheHelpers.insert_acl(domain.id, "Data Owner", [user.id])
      CacheHelpers.insert_group_acl(domain.id, "Data Owner", [group.id])

      business_concept_upload = %{path: "test/fixtures/upload_invalid_user_group_for_role.xlsx"}

      %{created: created, errors: errors} =
        Upload.bulk_upload(
          business_concept_upload,
          claims
        )

      assert Enum.count(created) == 2
      assert Enum.count(errors) == 1

      assert Enum.all?(created, fn version_id ->
               %{content: %{"data_owner" => %{"value" => data_owner}}} =
                 Repo.get!(BusinessConceptVersion, version_id)

               data_owner in ["user:user", "group:group"]
             end)
    end

    test "bulk_upload/3 creates content with multiple cardinality user/group field" do
      IndexWorker.clear()
      claims = build(:claims, role: "admin")
      domain = CacheHelpers.insert_domain(external_id: "domain")
      user = CacheHelpers.insert_user(full_name: "user")
      group = CacheHelpers.insert_group(name: "group")
      CacheHelpers.insert_acl(domain.id, "Data Owner", [user.id])
      CacheHelpers.insert_group_acl(domain.id, "Data Owner", [group.id])

      business_concept_upload = %{path: "test/fixtures/upload_multiple_user_group_for_role.xlsx"}

      %{created: [created], errors: [], updated: []} =
        Upload.bulk_upload(
          business_concept_upload,
          claims
        )

      assert %{content: %{"data_owner" => %{"value" => data_owners}}} =
               Repo.get!(BusinessConceptVersion, created)

      assert data_owners == ["user:user", "group:group"]
    end

    test "bulk_upload/3 uploads with auto publish create business concept and publish" do
      IndexWorker.clear()
      claims = build(:claims, role: "admin")

      insert(:domain, external_id: "domain")
      business_concept_upload = %{path: "test/fixtures/upload.xlsx"}

      assert %{created: [concept_id], updated: _, errors: _} =
               Upload.bulk_upload(
                 business_concept_upload,
                 claims,
                 lang: @default_lang,
                 auto_publish: true
               )

      version = BusinessConcepts.get_business_concept_version!(concept_id)
      assert IndexWorker.calls() == [{:reindex, :concepts, [version.business_concept.id]}]

      concept = Map.get(version, :business_concept)
      assert Map.get(concept, :confidential)

      assert version |> Map.get(:content) |> Map.get("role") == %{
               "value" => ["Role"],
               "origin" => "file"
             }

      assert version |> Map.get(:status) == "published"
      assert version |> Map.get(:current) == true
    end

    test "bulk_upload/3 uploads business concept versions as admin with hierarchy data" do
      IndexWorker.clear()
      claims = build(:claims, role: "admin")

      insert(:domain, external_id: "domain")
      business_concept_upload = %{path: "test/fixtures/upload_hierarchy.xlsx"}

      assert %{created: [concept_id], updated: _, errors: _} =
               Upload.bulk_upload(
                 business_concept_upload,
                 claims,
                 lang: @default_lang
               )

      version = BusinessConcepts.get_business_concept_version!(concept_id)
      assert IndexWorker.calls() == [{:reindex, :concepts, [version.business_concept.id]}]

      assert %{
               "hierarchy_name_1" => %{
                 "value" => "1_2",
                 "origin" => "file"
               },
               "hierarchy_name_2" => %{
                 "value" => ["1_2", "1_1"],
                 "origin" => "file"
               }
             } = Map.get(version, :content)
    end

    test "bulk_upload/3 get error business concept versions with invalid hierarchy data" do
      claims = build(:claims, role: "admin")
      insert(:domain, external_id: "domain")
      business_concept_upload = %{path: "test/fixtures/upload_invalid_hierarchy.xlsx"}

      assert %{
               created: [],
               updated: [],
               errors: [
                 %{
                   body: %{
                     context: %{
                       error:
                         "hierarchy_name_2: has more than one node children_2 - hierarchy_name_1: has more than one node children_2",
                       field: :content,
                       row: 2,
                       type: "term"
                     },
                     message: "concepts.upload.failed.invalid_field_value"
                   },
                   error_type: "field_error"
                 }
               ]
             } =
               Upload.bulk_upload(
                 business_concept_upload,
                 claims,
                 lang: @default_lang
               )
    end

    test "bulk_upload/3 uploads business concept with translation" do
      IndexWorker.clear()
      claims = build(:claims, role: "admin")

      insert(:domain, external_id: "domain")
      business_concept_upload = %{path: "test/fixtures/upload_translations.xlsx"}

      assert %{created: [concept_id], updated: _, errors: _} =
               Upload.bulk_upload(
                 business_concept_upload,
                 claims,
                 lang: "es"
               )

      version = BusinessConcepts.get_business_concept_version!(concept_id)
      assert IndexWorker.calls() == [{:reindex, :concepts, [version.business_concept.id]}]

      assert %{
               "i18n_test.checkbox" => %{"value" => ["apple", "pear"], "origin" => "file"},
               "i18n_test.dropdown" => %{"value" => "pear", "origin" => "file"},
               "i18n_test.radio" => %{"value" => "banana", "origin" => "file"},
               "i18n_test.no_translate" => %{"value" => "NO TRANSLATION", "origin" => "file"}
             } = Map.get(version, :content)
    end

    test "bulk_upload/3 uploads business concept in differents status without auto publish" do
      IndexWorker.clear()
      claims = build(:claims, role: "admin")

      domain = insert(:domain, external_id: "domain")

      bc_published = insert(:business_concept, domain: domain, id: 1, type: "term")

      %{id: bcv_published_id} =
        insert(:business_concept_version,
          name: "Name1",
          status: "published",
          business_concept: bc_published,
          id: 11
        )

      bc_deprecated = insert(:business_concept, domain: domain, id: 2, type: "term")

      %{id: bcv_deprecated_id} =
        insert(:business_concept_version,
          name: "Name2",
          status: "deprecated",
          business_concept: bc_deprecated,
          id: 22
        )

      bc_draft = insert(:business_concept, domain: domain, id: 3, type: "term")

      %{id: bcv_draft_id} =
        insert(:business_concept_version,
          name: "Name3",
          status: "draft",
          business_concept: bc_draft,
          id: 33
        )

      bc_pending_a = insert(:business_concept, domain: domain, id: 4, type: "term")

      %{id: bcv_pending_a_id} =
        insert(:business_concept_version,
          name: "Name4",
          status: "pending_approval",
          business_concept: bc_pending_a,
          id: 44
        )

      bc_rejected = insert(:business_concept, domain: domain, id: 5, type: "term")

      %{id: bcv_rejected_id} =
        insert(:business_concept_version,
          name: "Name5",
          status: "rejected",
          business_concept: bc_rejected,
          id: 55
        )

      business_concept_upload = %{path: "test/fixtures/upload_status_changes.xlsx"}

      # Only must be versioned bc_published that is inserted the first
      assert %{created: [], updated: [_ | _] = [bcv_new_version | bcv_versioned], errors: []} =
               Upload.bulk_upload(
                 business_concept_upload,
                 claims,
                 lang: "en"
               )

      assert bcv_new_version != bcv_published_id
      assert %{status: "draft"} = BusinessConcepts.get_business_concept_version!(bcv_new_version)

      [bcv_deprecated_id, bcv_draft_id, bcv_pending_a_id, bcv_rejected_id]
      |> Enum.with_index()
      |> Enum.each(fn {bcv_id, i} ->
        assert Enum.at(bcv_versioned, i) == bcv_id

        case bcv_id do
          ^bcv_pending_a_id ->
            assert %{status: "pending_approval"} =
                     BusinessConcepts.get_business_concept_version!(bcv_id)

          _ ->
            assert %{status: "draft"} = BusinessConcepts.get_business_concept_version!(bcv_id)
        end
      end)

      assert IndexWorker.calls() == [
               {:reindex, :concepts, [bc_published.id]},
               {:reindex, :concepts, [bc_deprecated.id]},
               {:reindex, :concepts, [bc_draft.id]},
               {:reindex, :concepts, [bc_pending_a.id]},
               {:reindex, :concepts, [bc_rejected.id]}
             ]
    end

    test "bulk_upload/3 uploads business concepts from excel file with binary ids (not numbers in origin)" do
      IndexWorker.clear()
      claims = build(:claims, role: "admin")

      domain = insert(:domain, external_id: "aaa", name: "aaa")

      concept_1 = insert(:business_concept, domain: domain, id: 23_704, type: "Business Term")

      %{id: concept_1_version_id} =
        insert(:business_concept_version,
          name: "name 1",
          status: "draft",
          id: 24_073,
          business_concept: concept_1
        )

      concept_2 = insert(:business_concept, domain: domain, id: 23_703, type: "Business Term")

      %{id: concept_2_version_id} =
        insert(:business_concept_version,
          name: "name 2",
          status: "draft",
          id: 24_071,
          business_concept: concept_2
        )

      business_concept_upload = %{path: "test/fixtures/upload_excel_with_binary_ids.xlsx"}

      assert %{created: [], updated: [^concept_1_version_id, ^concept_2_version_id], errors: []} =
               Upload.bulk_upload(
                 business_concept_upload,
                 claims,
                 lang: "en"
               )

      assert %{name: "Prueba hora"} =
               BusinessConcepts.get_business_concept_version!(concept_1_version_id)

      assert %{name: "Prueba hora new_name"} =
               BusinessConcepts.get_business_concept_version!(concept_2_version_id)

      assert IndexWorker.calls() == [
               {:reindex, :concepts, [concept_1.id]},
               {:reindex, :concepts, [concept_2.id]}
             ]
    end

    test "bulk_upload/3 updates business concepts taking into account their progress status when field in content is missing" do
      IndexWorker.clear()
      claims = build(:claims, role: "admin")

      domain = insert(:domain, external_id: "domain", name: "domain")

      concept = insert(:business_concept, domain: domain, type: "term", id: 3_244)

      %{id: version_id} =
        insert(:business_concept_version,
          name: "name 1",
          status: "draft",
          business_concept: concept,
          in_progress: false
        )

      business_concept_upload = %{path: "test/fixtures/incorrect_upload_update.xlsx"}

      assert %{created: [], errors: [], updated: [^version_id]} =
               Upload.bulk_upload(
                 business_concept_upload,
                 claims,
                 lang: "en"
               )

      business_concept_version = Repo.get!(BusinessConceptVersion, version_id)
      assert business_concept_version.in_progress
    end

    test "bulk_upload/3 uploads business concept in differents status with auto publish" do
      IndexWorker.clear()
      claims = build(:claims, role: "admin")

      domain = insert(:domain, external_id: "domain")

      bc_published = insert(:business_concept, domain: domain, id: 1, type: "term")

      %{id: bcv_published_id} =
        insert(:business_concept_version,
          name: "Name1",
          status: "published",
          business_concept: bc_published,
          id: 11
        )

      bc_deprecated = insert(:business_concept, domain: domain, id: 2, type: "term")

      %{id: bcv_deprecated_id} =
        insert(:business_concept_version,
          name: "Name2",
          status: "deprecated",
          version: 1,
          business_concept: bc_deprecated,
          id: 22
        )

      bc_draft = insert(:business_concept, domain: domain, id: 3, type: "term")

      %{id: bcv_draft_id} =
        insert(:business_concept_version,
          name: "Name3",
          status: "draft",
          version: 1,
          business_concept: bc_draft,
          id: 33
        )

      bc_pending_a = insert(:business_concept, domain: domain, id: 4, type: "term")

      %{id: bcv_pending_a_id} =
        insert(:business_concept_version,
          name: "Name4",
          status: "pending_approval",
          version: 1,
          business_concept: bc_pending_a,
          id: 44
        )

      bc_rejected = insert(:business_concept, domain: domain, id: 5, type: "term")

      %{id: bcv_rejected_id} =
        insert(:business_concept_version,
          name: "Name5",
          status: "rejected",
          version: 1,
          business_concept: bc_rejected,
          id: 55
        )

      business_concept_upload = %{path: "test/fixtures/upload_status_changes.xlsx"}

      # Only must be versioned bc_published that is inserted the first
      assert %{created: [], updated: [_ | _] = [bcv_new_version | bcv_versioned], errors: []} =
               Upload.bulk_upload(
                 business_concept_upload,
                 claims,
                 lang: "en",
                 auto_publish: true
               )

      assert bcv_new_version != bcv_published_id

      assert %{status: "published"} =
               BusinessConcepts.get_business_concept_version!(bcv_new_version)

      assert %{status: "versioned"} =
               BusinessConcepts.get_business_concept_version!(bcv_published_id)

      [bcv_deprecated_id, bcv_draft_id, bcv_pending_a_id, bcv_rejected_id]
      |> Enum.with_index()
      |> Enum.each(fn {bcv_id, i} ->
        assert Enum.at(bcv_versioned, i) == bcv_id

        assert %{status: "published", version: 1, current: true} =
                 BusinessConcepts.get_business_concept_version!(bcv_id)
      end)

      assert IndexWorker.calls() == [
               {:reindex, :concepts, [bc_published.id]},
               {:reindex, :concepts, [bc_published.id]},
               {:reindex, :concepts, [bc_deprecated.id]},
               {:reindex, :concepts, [bc_draft.id]},
               {:reindex, :concepts, [bc_pending_a.id]},
               {:reindex, :concepts, [bc_rejected.id]}
             ]
    end

    test "bulk_upload/3 update concept published with new draft/pending/rejected version and autopublish" do
      IndexWorker.clear()
      claims = build(:claims, role: "admin")

      domain = insert(:domain, external_id: "domain")

      %{id: bc_published_pending_id} =
        bc_published_pending = insert(:business_concept, domain: domain, id: 1, type: "term")

      %{id: bc_published_rejected_id} =
        bc_published_rejected = insert(:business_concept, domain: domain, id: 2, type: "term")

      %{id: bc_published_draft_id} =
        bc_published_draft = insert(:business_concept, domain: domain, id: 3, type: "term")

      %{id: bcv_published_pending_id} =
        insert(:business_concept_version,
          name: "Name1",
          status: "published",
          version: 1,
          business_concept: bc_published_pending,
          id: 11,
          current: true
        )

      %{id: bcv_pending_id} =
        insert(:business_concept_version,
          name: "Name1",
          status: "pending_aproval",
          version: 2,
          business_concept: bc_published_pending,
          id: 111,
          current: false
        )

      %{id: bcv_published_rejected_id} =
        insert(:business_concept_version,
          name: "Name2",
          status: "published",
          version: 1,
          business_concept: bc_published_rejected,
          id: 22,
          current: true
        )

      %{id: bcv_rejected_id} =
        insert(:business_concept_version,
          name: "Name2",
          status: "rejected",
          version: 2,
          business_concept: bc_published_rejected,
          id: 222,
          current: false
        )

      %{id: bcv_published_draft_id} =
        insert(:business_concept_version,
          name: "Name3",
          status: "published",
          version: 1,
          business_concept: bc_published_draft,
          id: 33,
          current: true
        )

      %{id: bcv_draft_id} =
        insert(:business_concept_version,
          name: "Name3",
          status: "draft",
          version: 2,
          business_concept: bc_published_draft,
          id: 333,
          current: false
        )

      business_concept_upload = %{path: "test/fixtures/upload_publish_status_changes.xlsx"}

      assert %{
               created: [],
               updated:
                 [_ | _] = [
                   bcv_pending_to_published_id,
                   bcv_rejected_to_published,
                   bcv_draft_to_published
                 ],
               errors: []
             } =
               Upload.bulk_upload(
                 business_concept_upload,
                 claims,
                 lang: "en",
                 auto_publish: true
               )

      # Check pending approval changes

      assert bcv_pending_to_published_id === bcv_pending_id

      assert %{
               id: ^bcv_pending_id,
               current: true,
               status: "published",
               business_concept: %{id: ^bc_published_pending_id}
             } = BusinessConcepts.get_business_concept_version!(bcv_pending_to_published_id)

      assert %{
               status: "versioned",
               current: false,
               business_concept: %{id: ^bc_published_pending_id}
             } = BusinessConcepts.get_business_concept_version!(bcv_published_pending_id)

      # Check rejected changes

      assert bcv_rejected_to_published === bcv_rejected_id

      assert %{
               id: ^bcv_rejected_id,
               current: true,
               status: "published",
               business_concept: %{id: ^bc_published_rejected_id}
             } = BusinessConcepts.get_business_concept_version!(bcv_rejected_to_published)

      assert %{
               status: "versioned",
               current: false,
               business_concept: %{id: ^bc_published_rejected_id}
             } = BusinessConcepts.get_business_concept_version!(bcv_published_rejected_id)

      # Check draft changes

      assert bcv_draft_to_published === bcv_draft_id

      assert %{
               id: ^bcv_draft_id,
               current: true,
               status: "published",
               business_concept: %{id: ^bc_published_draft_id}
             } = BusinessConcepts.get_business_concept_version!(bcv_draft_to_published)

      assert %{
               status: "versioned",
               current: false,
               business_concept: %{id: ^bc_published_draft_id}
             } = BusinessConcepts.get_business_concept_version!(bcv_published_draft_id)
    end

    test "bulk_upload/3 returns error on missing content field for auto-published version, creates it as `in_progress` otherwise" do
      claims = build(:claims, role: "admin")
      insert(:domain, external_id: "domain")
      business_concept_upload = %{path: "test/fixtures/incorrect_upload_missing_field.xlsx"}

      assert %{
               created: [],
               errors: [
                 %{
                   body: %{
                     context: %{
                       error: "role: can't be blank",
                       field: :content,
                       row: 2,
                       type: "term"
                     },
                     message: "concepts.upload.failed.invalid_field_value"
                   },
                   error_type: "field_error"
                 }
               ],
               updated: []
             } =
               Upload.bulk_upload(
                 business_concept_upload,
                 claims,
                 lang: @default_lang,
                 auto_publish: true
               )

      assert %{created: [id]} =
               Upload.bulk_upload(
                 business_concept_upload,
                 claims,
                 lang: @default_lang
               )

      created_business_concept_version = Repo.get!(BusinessConceptVersion, id)
      assert created_business_concept_version.in_progress
    end

    test "bulk_upload/3 Does not upload business concept versions without permissions" do
      claims = build(:claims)
      insert(:domain, external_id: "domain", name: "fobidden_domain")
      business_concept_upload = %{path: "test/fixtures/upload.xlsx"}

      assert %{
               created: [],
               errors: [
                 %{
                   body: %{
                     context: %{domain: "domain", row: 2, type: "term"},
                     message: "concepts.upload.failed.forbidden_creation"
                   },
                   error_type: "forbidden_creation"
                 }
               ],
               updated: []
             } =
               Upload.bulk_upload(
                 business_concept_upload,
                 claims,
                 lang: @default_lang
               )
    end

    test "bulk_upload/3 causes error if required header is missing" do
      claims = build(:claims, role: "admin")
      insert(:domain, external_id: "domain", name: "fobidden_domain")
      business_concept_upload = %{path: "test/fixtures/upload_missing_required_header.xlsx"}

      assert %{
               created: [],
               errors: [
                 %{
                   body: %{
                     context: %{headers: ["name"], type: "term"},
                     message: "concepts.upload.failed.header"
                   },
                   error_type: "missing_headers_error"
                 }
               ],
               updated: []
             } =
               Upload.bulk_upload(
                 business_concept_upload,
                 claims,
                 lang: @default_lang
               )
    end

    test "bulk_upload/3 causes error if domain is changed" do
      claims = build(:claims, role: "admin")

      insert(:domain, external_id: "domain2")
      domain = insert(:domain, external_id: "domain")

      bc = insert(:business_concept, domain: domain, id: 1, type: "term")
      insert(:business_concept_version, business_concept: bc, id: 11)

      business_concept_upload = %{path: "test/fixtures/upload_domain_changed.xlsx"}

      assert %{
               created: [],
               errors: [
                 %{
                   body: %{
                     context: %{
                       domain: "domain2",
                       row: 2,
                       type: "term"
                     },
                     message: "concepts.upload.failed.domain_changed"
                   },
                   error_type: "domain_can_not_be_changed"
                 }
               ],
               updated: []
             } =
               Upload.bulk_upload(
                 business_concept_upload,
                 claims,
                 lang: @default_lang
               )
    end

    test "bulk_upload/3 causes error if business concept to update not exists" do
      claims = build(:claims, role: "admin")

      insert(:domain, external_id: "domain2")

      business_concept_upload = %{path: "test/fixtures/upload_domain_changed.xlsx"}

      assert %{
               created: [],
               errors: [
                 %{
                   body: %{
                     context: %{
                       id: 1,
                       row: 2,
                       type: "term"
                     },
                     message: "concepts.upload.failed.business_concept_not_exists"
                   },
                   error_type: "business_concept_not_exists"
                 }
               ],
               updated: []
             } =
               Upload.bulk_upload(
                 business_concept_upload,
                 claims,
                 lang: @default_lang
               )
    end

    test "bulk_upload/3 causes error if template not exists" do
      claims = build(:claims, role: "admin")
      insert(:domain, external_id: "domain", name: "fobidden_domain")
      business_concept_upload = %{path: "test/fixtures/upload_template_not_exists.xlsx"}

      assert %{
               created: [],
               errors: [
                 %{
                   body: %{
                     context: %{template: "foo"},
                     message: "concepts.upload.failed.invalid_template"
                   },
                   error_type: "template_not_exists"
                 }
               ],
               updated: []
             } =
               Upload.bulk_upload(
                 business_concept_upload,
                 claims,
                 lang: @default_lang
               )
    end

    test "bulk_upload/3 row errors" do
      claims = get_auth_claims()
      CacheHelpers.insert_domain(%{external_id: "creation"})
      domain_update = CacheHelpers.insert_domain(%{external_id: "update"})
      %{id: domain_auto_publish_id} = CacheHelpers.insert_domain(%{external_id: "auto_publish"})

      CacheHelpers.put_session_permissions(claims, domain_auto_publish_id, [
        :create_business_concept
      ])

      bc = insert(:business_concept, domain: domain_update, id: 123, type: "term")

      insert(:business_concept_version,
        name: "Name3",
        status: "draft",
        business_concept: bc,
        id: 1234
      )

      business_concept_upload = %{path: "test/fixtures/upload_row_casuistics.xlsx"}

      assert %{
               created: [],
               errors: [
                 %{
                   body: %{
                     context: %{domain: "domain", row: 2, type: "term"},
                     message: "concepts.upload.failed.invalid_domain"
                   },
                   error_type: "domain_not_exists"
                 },
                 %{
                   body: %{
                     context: %{domain: "creation", row: 3, type: "term"},
                     message: "concepts.upload.failed.forbidden_creation"
                   },
                   error_type: "forbidden_creation"
                 },
                 %{
                   body: %{
                     context: %{domain: "update", row: 4, type: "term"},
                     message: "concepts.upload.failed.forbidden_update"
                   },
                   error_type: "forbidden_update"
                 },
                 %{
                   body: %{
                     context: %{domain: "auto_publish", row: 5, type: "term"},
                     message: "concepts.upload.failed.forbidden_publish"
                   },
                   error_type: "forbidden_publish"
                 }
               ],
               updated: []
             } =
               Upload.bulk_upload(
                 business_concept_upload,
                 claims,
                 lang: @default_lang,
                 auto_publish: true
               )
    end

    test "bulk_upload/3 row with not available name" do
      claims = build(:claims, role: "admin")
      %{id: domain_id} = insert(:domain, external_id: "domain")

      business_concept_upload = %{path: "test/fixtures/upload.xlsx"}

      bc = insert(:business_concept, domain_id: domain_id, type: "term")
      insert(:business_concept_version, name: "name", business_concept: bc, status: "published")

      assert %{
               created: [],
               updated: [],
               errors: [
                 %{
                   body: %{
                     context: %{
                       name: "name",
                       type: "term",
                       row: 2
                     },
                     message: "concepts.upload.failed.name_not_available"
                   },
                   error_type: "name_not_available"
                 }
               ]
             } =
               Upload.bulk_upload(
                 business_concept_upload,
                 claims,
                 lang: @default_lang
               )
    end

    test "bulk_upload/3 doesn't return validation errors when concept is in draft" do
      claims = build(:claims, role: "admin")
      insert(:domain, external_id: "domain")

      business_concept_upload = %{
        path: "test/fixtures/upload_invalid_multiple_cardinality_fields.xlsx"
      }

      assert %{created: [], errors: [error]} =
               Upload.bulk_upload(
                 business_concept_upload,
                 claims,
                 lang: @default_lang
               )

      assert error.body.context.error == "multiple_values: has an invalid entry"
      assert error.body.context.field == :content
      assert error.body.message == "concepts.upload.failed.invalid_field_value"
    end

    test "bulk_upload/3 does not publish concept when content is invalid and there are no changes over the previous version" do
      claims = build(:claims, role: "admin")
      domain = insert(:domain, external_id: "domain")

      concept =
        insert(:business_concept, domain: domain, id: 50, type: "Multiple cardinality validation")

      %{id: _id} =
        insert(:business_concept_version,
          status: "draft",
          business_concept: concept,
          content: %{
            "hierarchy_name_multiple" => %{"value" => [], "origin" => "file"},
            "multiple_values" => %{"value" => [], "origin" => "file"}
          },
          id: 11
        )

      business_concept_upload = %{
        path: "test/fixtures/upload_empty_multiple_cardinality_fields.xlsx"
      }

      assert %{created: [], errors: [error]} =
               Upload.bulk_upload(
                 business_concept_upload,
                 claims,
                 lang: @default_lang,
                 auto_publish: true
               )

      assert error.body.context.error ==
               "multiple_values: should have at least %{count} item(s) - hierarchy_name: can't be blank"
    end

    test "bulk_upload/3 upload table type values" do
      claims = build(:claims, role: "admin")
      insert(:domain, external_id: "Tests ext id")

      business_concept_upload = %{
        path: "test/fixtures/upload_table.xlsx"
      }

      assert %{created: [version_id], errors: [], updated: []} =
               Upload.bulk_upload(
                 business_concept_upload,
                 claims,
                 lang: @default_lang
               )

      assert Repo.get!(BusinessConceptVersion, version_id).content == %{
               "Multiple values" => %{"origin" => "file", "value" => ["v-1", "v-2"]},
               "Table Field" => %{
                 "origin" => "file",
                 "value" => [
                   %{"First Column" => "First Field", "Second Column" => "Second Field"},
                   %{"First Column" => "Third Field", "Second Column" => "Fourth Field"}
                 ]
               }
             }
    end

    test "bulk_upload/3 invalid table values upload" do
      claims = build(:claims, role: "admin")
      insert(:domain, external_id: "Tests ext id")

      business_concept_upload = %{
        path: "test/fixtures/invalid_table_upload.xlsx"
      }

      # on auto publish required columns should be validated
      assert %{created: [], errors: [error], updated: []} =
               Upload.bulk_upload(
                 business_concept_upload,
                 claims,
                 lang: @default_lang,
                 auto_publish: true
               )

      assert error == %{
               body: %{
                 context: %{
                   error:
                     "Table Field: Second Column can't be blank - Table Field: First Column can't be blank",
                   field: :content,
                   row: 2,
                   type: "Table Template"
                 },
                 message: "concepts.upload.failed.invalid_field_value"
               },
               error_type: "field_error"
             }

      # when auto publish is disabled, the version is saved in progress for further
      assert %{created: [version_id], errors: [], updated: []} =
               Upload.bulk_upload(
                 business_concept_upload,
                 claims,
                 lang: @default_lang
               )

      business_concept_version = Repo.get!(BusinessConceptVersion, version_id)

      assert business_concept_version.content == %{
               "Multiple values" => %{"origin" => "file", "value" => ["v-1", "v-2"]},
               "Table Field" => %{
                 "origin" => "file",
                 "value" => [
                   %{"First Column" => "", "Second Column" => "Second Field"},
                   %{"First Column" => "Third Field", "Second Column" => ""},
                   %{"First Column" => "", "Second Column" => ""}
                 ]
               }
             }

      assert business_concept_version.in_progress
    end
  end

  describe "get_headers?/0" do
    test "returns headers grouped by required" do
      assert %{
               required: ["name", "domain_external_id"],
               update_required: ["id"],
               ignored: ["domain_name" | _]
             } = Upload.get_headers()
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

  defp get_auth_claims do
    auth_opts = [user_name: "not_an_admin", permissions: []]

    auth_opts
    |> Authentication.create_claims()
    |> Authentication.create_user_auth_conn()
    |> Authentication.assign_permissions(auth_opts[:permissions])
    |> Keyword.get(:claims)
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
