defmodule TdBg.UploadTest do
  use TdBg.DataCase

  import Mox

  alias TdBg.BusinessConcept.Upload
  alias TdBg.BusinessConcepts
  alias TdBgWeb.Authentication
  alias TdCache.HierarchyCache
  alias TdCore.Search.IndexWorkerMock

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

  @default_lang "en"

  setup_all do
    start_supervised!(TdBg.Cache.ConceptLoader)
    :ok
  end

  setup _context do
    %{id: template_id} = template = Templates.create_template(@default_template)
    %{id: i18n_template_id} = i18n_template = Templates.create_template(@i18n_template)
    %{id: concept_template_id} = concept_template = Templates.create_template(@concept_template)

    %{id: hierarchy_id} = hierarchy = create_hierarchy()
    HierarchyCache.put(hierarchy)

    on_exit(fn ->
      IndexWorkerMock.clear()
      Templates.delete(template_id)
      Templates.delete(i18n_template_id)
      Templates.delete(concept_template_id)
      HierarchyCache.delete(hierarchy_id)
    end)

    [
      template: template,
      i18n_template: i18n_template,
      concept_template: concept_template,
      hierarchy: hierarchy
    ]
  end

  setup :verify_on_exit!

  describe "business_concept_upload" do
    setup [:set_mox_from_context, :insert_i18n_messages]

    test "bulk_upload/3 uploads business concept versions as admin with valid data" do
      IndexWorkerMock.clear()
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
      assert IndexWorkerMock.calls() == [{:reindex, :concepts, [version.business_concept.id]}]

      concept = Map.get(version, :business_concept)
      assert Map.get(concept, :confidential)
      assert version |> Map.get(:content) |> Map.get("role") == ["Role"]
      IndexWorkerMock.clear()
    end

    test "bulk_upload/3 uploads with auto publish create business concept and publish" do
      IndexWorkerMock.clear()
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
      assert IndexWorkerMock.calls() == [{:reindex, :concepts, [version.business_concept.id]}]

      concept = Map.get(version, :business_concept)
      assert Map.get(concept, :confidential)
      assert version |> Map.get(:content) |> Map.get("role") == ["Role"]
      assert version |> Map.get(:status) == "published"
      assert version |> Map.get(:current) == true
      IndexWorkerMock.clear()
    end

    test "bulk_upload/3 uploads business concept versions as admin with hierarchy data" do
      IndexWorkerMock.clear()
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
      assert IndexWorkerMock.calls() == [{:reindex, :concepts, [version.business_concept.id]}]

      assert %{
               "hierarchy_name_1" => "1_2",
               "hierarchy_name_2" => ["1_2", "1_1"]
             } = Map.get(version, :content)

      IndexWorkerMock.clear()
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
                       error: "invalid content - invalid content",
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
      IndexWorkerMock.clear()
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
      assert IndexWorkerMock.calls() == [{:reindex, :concepts, [version.business_concept.id]}]

      assert %{
               "i18n_test.checkbox" => ["apple", "pear"],
               "i18n_test.dropdown" => "pear",
               "i18n_test.radio" => "banana",
               "i18n_test.no_translate" => "NO TRANSLATION"
             } = Map.get(version, :content)

      IndexWorkerMock.clear()
    end

    test "bulk_upload/3 uploads business concept in differents status without auto publish" do
      IndexWorkerMock.clear()
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
        assert %{status: "draft"} = BusinessConcepts.get_business_concept_version!(bcv_id)
      end)

      assert IndexWorkerMock.calls() == [
               {:reindex, :concepts, [bc_published.id]},
               {:reindex, :concepts, [bc_deprecated.id]},
               {:reindex, :concepts, [bc_draft.id]},
               {:reindex, :concepts, [bc_pending_a.id]},
               {:reindex, :concepts, [bc_rejected.id]}
             ]

      IndexWorkerMock.clear()
    end

    test "bulk_upload/3 uploads business concepts from excel file with binary ids (not numbers in origin)" do
      IndexWorkerMock.clear()
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

      assert IndexWorkerMock.calls() == [
               {:reindex, :concepts, [concept_1.id]},
               {:reindex, :concepts, [concept_2.id]}
             ]

      IndexWorkerMock.clear()
    end

    test "bulk_upload/3 uploads business concept in differents status with auto publish" do
      IndexWorkerMock.clear()
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

        assert %{status: "published", current: true} =
                 BusinessConcepts.get_business_concept_version!(bcv_id)
      end)

      assert IndexWorkerMock.calls() == [
               {:reindex, :concepts, [bc_published.id]},
               {:reindex, :concepts, [bc_published.id]},
               {:reindex, :concepts, [bc_deprecated.id]},
               {:reindex, :concepts, [bc_draft.id]},
               {:reindex, :concepts, [bc_pending_a.id]},
               {:reindex, :concepts, [bc_rejected.id]}
             ]

      IndexWorkerMock.clear()
    end

    test "bulk_upload/3 returns error on invalid content" do
      claims = build(:claims, role: "admin")
      insert(:domain, external_id: "domain")
      business_concept_upload = %{path: "test/fixtures/incorrect_upload.xlsx"}

      assert %{
               created: [],
               errors: [
                 %{
                   body: %{
                     context: %{
                       error: "role: can't be blank - critical: is invalid",
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
                 lang: @default_lang
               )
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
