defmodule TdBg.UploadTest do
  alias TdCache.TemplateCache
  use TdBg.DataCase

  import Mox

  alias TdBg.BusinessConcept.Upload
  alias TdBg.BusinessConcepts
  alias TdBg.BusinessConcepts.BusinessConceptVersion
  alias TdBg.I18nContents.I18nContent
  alias TdBg.I18nContents.I18nContents
  alias TdBgWeb.Authentication
  alias TdCache.HierarchyCache
  alias TdCache.I18nCache
  alias TdCore.Search.IndexWorkerMock

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
          },
          %{
            "cardinality" => "*",
            "default" => %{"origin" => "default", "value" => ""},
            "label" => "URL",
            "name" => "input_url",
            "type" => "url",
            "widget" => "pair_list",
            "values" => nil
          },
          %{
            "name" => "father",
            "type" => "string",
            "label" => "father",
            "values" => %{"fixed" => ["a1", "a2", "b1", "b2"]},
            "widget" => "dropdown",
            "default" => %{"value" => "", "origin" => "default"},
            "cardinality" => "?",
            "subscribable" => false,
            "ai_suggestion" => false
          },
          %{
            "name" => "son",
            "type" => "string",
            "label" => "son",
            "values" => %{
              "switch" => %{
                "on" => "father",
                "values" => %{
                  "a1" => ["a11", "a12", "a13"],
                  "a2" => ["a21", "a22", "a23"],
                  "b1" => ["b11", "b12", "b13"],
                  "b2" => ["b21", "b22", "b23"]
                }
              }
            },
            "widget" => "dropdown",
            "default" => %{"value" => "", "origin" => "default"},
            "cardinality" => "?",
            "subscribable" => false,
            "ai_suggestion" => false
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
            "name" => "df_description",
            "type" => "enriched_text",
            "label" => "Description",
            "values" => nil,
            "widget" => "enriched_text",
            "default" => %{"value" => "", "origin" => "default"},
            "cardinality" => "?",
            "description" => "description",
            "subscribable" => false,
            "ai_suggestion" => true
          },
          %{
            "cardinality" => "?",
            "label" => "i18n_test.translate",
            "name" => "i18n_test.translate",
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
            "widget" => "dropdown",
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
            "widget" => "table",
            "values" => %{
              "table_columns" => [
                %{"name" => "First Column", "mandatory" => true},
                %{"name" => "Second Column", "mandatory" => true}
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

  @dynamic_concept_table_validation %{
    name: "Table Template",
    content: [
      %{
        "name" => "group",
        "fields" => [
          %{
            "name" => "Table Field",
            "label" => "Table Field",
            "type" => "dynamic_table",
            "cardinality" => "*",
            "widget" => "dynamic_table",
            "values" => %{
              "table_columns" => [
                %{"name" => "First Column", "cardinality" => "1", "type" => "string"},
                %{"name" => "Second Column", "cardinality" => "1", "type" => "string"}
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

    %{id: table_template_id} =
      table_template = Templates.create_template(@concept_table_validation)

    %{id: hierarchy_id} = hierarchy = create_hierarchy()
    HierarchyCache.put(hierarchy)
    I18nCache.put_default_locale(@default_lang)

    stub(MockClusterHandler, :call, fn :ai, TdAi.Indices, :exists_enabled?, [] ->
      {:ok, true}
    end)

    on_exit(fn ->
      IndexWorkerMock.clear()
      TdCache.Redix.del!("i18n:locales:*")
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
      hierarchy: hierarchy,
      table_template: table_template
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

      assert Map.get(version, :content) == %{
               "critical" => %{"origin" => "file", "value" => "Yes"},
               "description" => %{"origin" => "file", "value" => ["Test"]},
               "input_float" => %{"origin" => "file", "value" => 12.5},
               "input_integer" => %{"origin" => "file", "value" => 12},
               "input_url" => %{
                 "origin" => "file",
                 "value" => [
                   %{"url_name" => "com", "url_value" => "www.com.com"},
                   %{"url_name" => "", "url_value" => "www.net.net"},
                   %{"url_name" => "", "url_value" => "www.org.org"}
                 ]
               },
               "role" => %{"origin" => "file", "value" => ["Role"]}
             }
    end

    test "updates i18n without changing values from removed columns" do
      IndexWorkerMock.clear()
      claims = build(:claims, role: "admin")

      domain = insert(:domain, external_id: "domain")
      concept = insert(:business_concept, domain: domain, type: "term", id: 1_000)

      %{id: version_id} =
        insert(:business_concept_version,
          name: "original name",
          status: "draft",
          business_concept: concept,
          in_progress: false,
          content: %{"description" => %{"value" => ["test"], "origin" => "user"}}
        )

      i18n_content = %{"description" => %{"value" => ["prueba"], "origin" => "user"}}

      %{id: content_id} =
        insert(:i18n_content,
          business_concept_version_id: version_id,
          name: "nombre original",
          content: i18n_content,
          lang: "es"
        )

      business_concept_upload = %{path: "test/fixtures/upload_missing_column.xlsx"}

      assert %{errors: [], created: [], updated: [updated_id]} =
               Upload.bulk_upload(
                 business_concept_upload,
                 claims,
                 lang: @default_lang
               )

      version = Repo.get!(BusinessConceptVersion, updated_id)
      assert version.name == "name"
      assert version.content["description"] == %{"origin" => "user", "value" => ["test"]}
      content = Repo.get!(I18nContent, content_id)
      assert content.name == "nombre"
      assert content.content == i18n_content
    end

    test "version published concept on i18n content update" do
      IndexWorkerMock.clear()
      claims = build(:claims, role: "admin")

      domain = insert(:domain, external_id: "domain")
      concept = insert(:business_concept, domain: domain, type: "term", id: 1_000)

      %{id: version_id, version: version_number} =
        insert(:business_concept_version,
          name: "original name",
          status: "published",
          business_concept: concept,
          in_progress: false,
          version: 1,
          content: %{
            "critical" => %{"origin" => "user", "value" => "Yes"},
            "description" => %{"origin" => "user", "value" => ["test"]},
            "input_float" => %{"origin" => "user", "value" => 12.5},
            "input_integer" => %{"origin" => "user", "value" => 12},
            "input_url" => %{
              "origin" => "user",
              "value" => [
                %{"url_name" => "com", "url_value" => "www.com.com"},
                %{"url_name" => "", "url_value" => "www.net.net"},
                %{"url_name" => "", "url_value" => "www.org.org"}
              ]
            },
            "role" => %{"origin" => "user", "value" => ["Role"]}
          }
        )

      i18n_content = %{"description" => %{"value" => ["versionado"], "origin" => "user"}}

      insert(:i18n_content,
        business_concept_version_id: version_id,
        name: "nombre original",
        content: i18n_content,
        lang: "es"
      )

      business_concept_upload = %{path: "test/fixtures/upload_version_on_content_update.xlsx"}

      assert %{errors: [], created: [], updated: [updated_id]} =
               Upload.bulk_upload(
                 business_concept_upload,
                 claims,
                 lang: @default_lang
               )

      updated_version = Repo.get!(BusinessConceptVersion, updated_id)

      assert updated_version.content["description"] == %{"value" => ["test"], "origin" => "file"}
      assert updated_version.version == version_number + 1
      content = Repo.get_by(I18nContent, business_concept_version_id: updated_id)
      assert content.content["description"] == %{"value" => ["prueba"], "origin" => "file"}
    end

    test "version published concept on i18n content update when auto publish is true" do
      IndexWorkerMock.clear()

      claims = build(:claims, role: "admin")

      domain = insert(:domain, external_id: "domain")
      concept = insert(:business_concept, domain: domain, type: "term", id: 1_000)

      %{id: version_id, version: version_number} =
        insert(:business_concept_version,
          name: "original name",
          status: "published",
          business_concept: concept,
          in_progress: false,
          version: 1,
          content: %{
            "critical" => %{"origin" => "user", "value" => "Yes"},
            "description" => %{"origin" => "user", "value" => ["test"]},
            "input_float" => %{"origin" => "user", "value" => 12.5},
            "input_integer" => %{"origin" => "user", "value" => 12},
            "input_url" => %{
              "origin" => "user",
              "value" => [
                %{"url_name" => "com", "url_value" => "www.com.com"},
                %{"url_name" => "", "url_value" => "www.net.net"},
                %{"url_name" => "", "url_value" => "www.org.org"}
              ]
            },
            "role" => %{"origin" => "user", "value" => ["Role"]}
          }
        )

      i18n_content = %{"description" => %{"value" => ["versionado"], "origin" => "user"}}

      insert(:i18n_content,
        business_concept_version_id: version_id,
        name: "nombre original",
        content: i18n_content,
        lang: "es"
      )

      business_concept_upload = %{path: "test/fixtures/upload_version_on_content_update.xlsx"}

      assert %{errors: [], created: [], updated: [updated_id]} =
               Upload.bulk_upload(
                 business_concept_upload,
                 claims,
                 lang: @default_lang,
                 auto_publish: true
               )

      updated_version = Repo.get!(BusinessConceptVersion, updated_id)

      assert updated_version.version == version_number + 1
      assert updated_version.content["description"] == %{"value" => ["test"], "origin" => "file"}
      content = Repo.get_by(I18nContent, business_concept_version_id: updated_id)
      assert content.content["description"] == %{"value" => ["prueba"], "origin" => "file"}
    end

    test "draft concept on i18n content update when auto publish is true" do
      IndexWorkerMock.clear()
      claims = build(:claims, role: "admin")

      domain = insert(:domain, external_id: "domain")
      concept = insert(:business_concept, domain: domain, type: "term", id: 1_000)

      %{id: version_id, version: version_number} =
        insert(:business_concept_version,
          name: "original name",
          status: "draft",
          business_concept: concept,
          in_progress: false,
          version: 1,
          content: %{
            "critical" => %{"origin" => "user", "value" => "Yes"},
            "description" => %{"origin" => "user", "value" => ["test"]},
            "input_float" => %{"origin" => "user", "value" => 12.5},
            "input_integer" => %{"origin" => "user", "value" => 12},
            "input_url" => %{
              "origin" => "user",
              "value" => [
                %{"url_name" => "com", "url_value" => "www.com.com"},
                %{"url_name" => "", "url_value" => "www.net.net"},
                %{"url_name" => "", "url_value" => "www.org.org"}
              ]
            },
            "role" => %{"origin" => "user", "value" => ["Role"]}
          }
        )

      i18n_content = %{}

      insert(:i18n_content,
        business_concept_version_id: version_id,
        name: "nombre original",
        content: i18n_content,
        lang: "es"
      )

      business_concept_upload = %{path: "test/fixtures/upload_version_on_content_update.xlsx"}

      assert %{errors: [], created: [], updated: [updated_id]} =
               Upload.bulk_upload(
                 business_concept_upload,
                 claims,
                 lang: @default_lang,
                 auto_publish: true
               )

      updated_version = Repo.get!(BusinessConceptVersion, updated_id)

      assert updated_version.version == version_number
      assert updated_version.content["description"] == %{"value" => ["test"], "origin" => "file"}
      content = Repo.get_by(I18nContent, business_concept_version_id: updated_id)
      assert content.content["description"] == %{"value" => ["prueba"], "origin" => "file"}
    end

    test "bulk_upload/3 returns error under invalid number" do
      IndexWorkerMock.clear()
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
      IndexWorkerMock.clear()
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
      IndexWorkerMock.clear()
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

      assert version |> Map.get(:content) |> Map.get("role") == %{
               "value" => ["Role"],
               "origin" => "file"
             }

      assert version |> Map.get(:status) == "published"
      assert version |> Map.get(:current) == true
    end

    test "bulk_upload/3 returns an error for business concept versions with valid hierarchy and dependent data" do
      IndexWorkerMock.clear()
      claims = build(:claims, role: "admin")

      insert(:domain, external_id: "domain")
      business_concept_upload = %{path: "test/fixtures/upload_hierarchy.xlsx"}

      assert %{created: [concept_id_1, concept_id_2], updated: _, errors: _} =
               Upload.bulk_upload(business_concept_upload, claims, lang: @default_lang)

      version_1 = BusinessConcepts.get_business_concept_version!(concept_id_1)
      version_2 = BusinessConcepts.get_business_concept_version!(concept_id_2)

      assert IndexWorkerMock.calls() == [
               {:reindex, :concepts, [version_1.business_concept.id]},
               {:reindex, :concepts, [version_2.business_concept.id]}
             ]

      assert %{
               "hierarchy_name_1" => %{"value" => "1_2", "origin" => "file"},
               "hierarchy_name_2" => %{"value" => ["1_2", "1_1"], "origin" => "file"},
               "father" => %{"origin" => "file", "value" => ""},
               "son" => %{"origin" => "file", "value" => ""}
             } = Map.get(version_1, :content)

      assert %{
               "hierarchy_name_1" => %{"value" => "1_2", "origin" => "file"},
               "hierarchy_name_2" => %{"value" => ["1_2", "1_1"], "origin" => "file"},
               "father" => %{"origin" => "file", "value" => "a1"},
               "son" => %{"origin" => "file", "value" => "a11"}
             } = Map.get(version_2, :content)
    end

    test "bulk_upload/3 returns an error for business concept versions with an invalid hierarchy and dependent data" do
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
                         "hierarchy_name_2: has more than one node children_2 - hierarchy_name_1: has more than one node children_2 - son: is invalid",
                       row: 2,
                       type: "term",
                       field: :content
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

      i18n_content = I18nContents.get_all_i18n_content_by_bcv_id(version.id)

      assert %{
               "i18n_test.checkbox" => %{"value" => ["apple", "pear"], "origin" => "file"},
               "i18n_test.dropdown" => %{"value" => "pear", "origin" => "file"},
               "i18n_test.radio" => %{"value" => "banana", "origin" => "file"},
               "i18n_test.no_translate" => %{"value" => "NO TRANSLATION", "origin" => "file"},
               "i18n_test.translate" => %{
                 "value" => "English Translation",
                 "origin" => "file"
               },
               "df_description" => %{
                 "origin" => "file",
                 "value" => %{
                   "document" => %{
                     "nodes" => [
                       %{
                         "nodes" => [
                           %{"leaves" => [%{"text" => "concept 1 en"}], "object" => "text"}
                         ],
                         "object" => "block",
                         "type" => "paragraph"
                       }
                     ]
                   }
                 }
               }
             } = Map.get(version, :content)

      assert [
               %{
                 lang: "es",
                 content: %{
                   "i18n_test.translate" => %{
                     "value" => "Traducción Español",
                     "origin" => "file"
                   },
                   "df_description" => %{
                     "origin" => "file",
                     "value" => %{
                       "document" => %{
                         "nodes" => [
                           %{
                             "nodes" => [
                               %{"leaves" => [%{"text" => "concept 1 es"}], "object" => "text"}
                             ],
                             "object" => "block",
                             "type" => "paragraph"
                           }
                         ]
                       }
                     }
                   }
                 },
                 name: "i18n_concept_1_es"
               }
             ] = i18n_content
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

        case bcv_id do
          ^bcv_pending_a_id ->
            assert %{status: "pending_approval"} =
                     BusinessConcepts.get_business_concept_version!(bcv_id)

          _ ->
            assert %{status: "draft"} = BusinessConcepts.get_business_concept_version!(bcv_id)
        end
      end)

      assert IndexWorkerMock.calls() == [
               {:reindex, :concepts, [bc_published.id]},
               {:reindex, :concepts, [bc_deprecated.id]},
               {:reindex, :concepts, [bc_draft.id]},
               {:reindex, :concepts, [bc_pending_a.id]},
               {:reindex, :concepts, [bc_rejected.id]}
             ]
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

      assert %{name: "Test time"} =
               BusinessConcepts.get_business_concept_version!(concept_1_version_id)

      assert %{name: "Test time new_name"} =
               BusinessConcepts.get_business_concept_version!(concept_2_version_id)

      assert IndexWorkerMock.calls() == [
               {:reindex, :concepts, [concept_1.id]},
               {:reindex, :concepts, [concept_2.id]}
             ]
    end

    test "bulk_upload/3 updates business concepts taking into account their progress status when field in content is missing" do
      IndexWorkerMock.clear()
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

      assert IndexWorkerMock.calls() == [
               {:reindex, :concepts, [bc_published.id]},
               {:reindex, :concepts, [bc_published.id]},
               {:reindex, :concepts, [bc_deprecated.id]},
               {:reindex, :concepts, [bc_draft.id]},
               {:reindex, :concepts, [bc_pending_a.id]},
               {:reindex, :concepts, [bc_rejected.id]}
             ]
    end

    test "bulk_upload/3 update concept published with new draft/pending/rejected version and autopublish" do
      IndexWorkerMock.clear()
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
                     context: %{headers: ["name_en"], type: "term"},
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
      %{claims: claims} = Authentication.create_claims(user_name: "not_an_admin")
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

    test "bulk_upload/3 upload dynamic table type values", %{table_template: table_template} do
      TemplateCache.delete(table_template.id)
      %{id: id} = Templates.create_template(@dynamic_concept_table_validation)
      on_exit(fn -> TemplateCache.delete(id) end)
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
                   %{
                     "First Column" => %{"value" => "First Field", "origin" => "file"},
                     "Second Column" => %{"value" => "Second Field", "origin" => "file"}
                   },
                   %{
                     "First Column" => %{"value" => "Third Field", "origin" => "file"},
                     "Second Column" => %{"value" => "Fourth Field", "origin" => "file"}
                   }
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

    test "bulk_upload/3 invalid dynamic table values upload", %{table_template: table_template} do
      TemplateCache.delete(table_template.id)
      %{id: id} = Templates.create_template(@dynamic_concept_table_validation)
      on_exit(fn -> TemplateCache.delete(id) end)
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
                     "Table Field: First Column column in table row 0 can't be blank - Table Field: Second Column column in table row 1 can't be blank - Table Field: Second Column column in table row 2 can't be blank - Table Field: First Column column in table row 2 can't be blank",
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
                   %{
                     "First Column" => %{"value" => "", "origin" => "file"},
                     "Second Column" => %{"value" => "Second Field", "origin" => "file"}
                   },
                   %{
                     "First Column" => %{"value" => "Third Field", "origin" => "file"},
                     "Second Column" => %{"value" => "", "origin" => "file"}
                   },
                   %{
                     "First Column" => %{"value" => "", "origin" => "file"},
                     "Second Column" => %{"value" => "", "origin" => "file"}
                   }
                 ]
               }
             }

      assert business_concept_version.in_progress
    end

    test "bulk_upload/3 for table values upload" do
      claims = build(:claims, role: "admin")
      insert(:domain, external_id: "Tests ext id")

      business_concept_upload = %{
        path: "test/fixtures/table_field_upload.xlsx"
      }

      assert %{created: version_ids, errors: [], updated: []} =
               Upload.bulk_upload(
                 business_concept_upload,
                 claims,
                 lang: @default_lang
               )

      expected_results = [
        [],
        [],
        [],
        [%{"First Column" => "Value A1", "Second Column" => "Value B1"}],
        [%{"First Column" => "Value A1", "Second Column" => "Value B1"}],
        [
          %{"First Column" => "Value A1", "Second Column" => "Value B1"},
          %{"First Column" => "Value A2", "Second Column" => "Value B2"}
        ],
        [
          %{"First Column" => "Value A1", "Second Column" => "Value B1"},
          %{"First Column" => "Value A2", "Second Column" => "Value B2"}
        ]
      ]

      [version_ids, expected_results]
      |> Enum.zip()
      |> Enum.map(fn {version_id, expected_result} ->
        assert expected_result ==
                 BusinessConceptVersion
                 |> Repo.get!(version_id)
                 |> Map.get(:content)
                 |> Map.get("Table Field")
                 |> Map.get("value")
      end)
    end

    test "bulk_upload/3 for dynamic table values upload", %{table_template: table_template} do
      TemplateCache.delete(table_template.id)
      %{id: id} = Templates.create_template(@dynamic_concept_table_validation)
      on_exit(fn -> TemplateCache.delete(id) end)
      claims = build(:claims, role: "admin")
      insert(:domain, external_id: "Tests ext id")

      business_concept_upload = %{
        path: "test/fixtures/table_field_upload.xlsx"
      }

      assert %{created: version_ids, errors: [], updated: []} =
               Upload.bulk_upload(
                 business_concept_upload,
                 claims,
                 lang: @default_lang
               )

      expected_results = [
        [],
        [],
        [],
        [
          %{
            "First Column" => %{"value" => "Value A1", "origin" => "file"},
            "Second Column" => %{"value" => "Value B1", "origin" => "file"}
          }
        ],
        [
          %{
            "First Column" => %{"value" => "Value A1", "origin" => "file"},
            "Second Column" => %{"value" => "Value B1", "origin" => "file"}
          }
        ],
        [
          %{
            "First Column" => %{"value" => "Value A1", "origin" => "file"},
            "Second Column" => %{"value" => "Value B1", "origin" => "file"}
          },
          %{
            "First Column" => %{"value" => "Value A2", "origin" => "file"},
            "Second Column" => %{"value" => "Value B2", "origin" => "file"}
          }
        ],
        [
          %{
            "First Column" => %{"value" => "Value A1", "origin" => "file"},
            "Second Column" => %{"value" => "Value B1", "origin" => "file"}
          },
          %{
            "First Column" => %{"value" => "Value A2", "origin" => "file"},
            "Second Column" => %{"value" => "Value B2", "origin" => "file"}
          }
        ]
      ]

      [version_ids, expected_results]
      |> Enum.zip()
      |> Enum.map(fn {version_id, expected_result} ->
        assert expected_result ==
                 BusinessConceptVersion
                 |> Repo.get!(version_id)
                 |> Map.get(:content)
                 |> Map.get("Table Field")
                 |> Map.get("value")
      end)
    end

    test "bulk_upload/3 for dynamic table values with multiple cardinality upload", %{
      table_template: table_template
    } do
      TemplateCache.delete(table_template.id)

      template =
        update_in(
          @dynamic_concept_table_validation,
          [:content, Access.at(0), "fields", Access.at(0), "values", "table_columns"],
          fn fields ->
            fields ++ [%{"name" => "Third Column", "cardinality" => "*", "type" => "string"}]
          end
        )

      %{id: id} = Templates.create_template(template)
      on_exit(fn -> TemplateCache.delete(id) end)

      business_concept_upload = %{
        path: "test/fixtures/table_field_upload_multiple.xlsx"
      }

      claims = build(:claims, role: "admin")
      insert(:domain, external_id: "Tests ext id")

      assert %{created: version_ids, errors: [], updated: []} =
               Upload.bulk_upload(
                 business_concept_upload,
                 claims,
                 lang: @default_lang
               )

      for id <- version_ids do
        BusinessConceptVersion
        |> Repo.get!(id)
        |> Map.get(:content)
        |> Map.get("Table Field")
        |> Map.get("value")
      end
    end
  end

  describe "get_headers?/0" do
    test "returns headers grouped by required without translations" do
      assert %{
               required: ["name", "domain_external_id"],
               update_required: ["id"],
               ignored: ["domain_name" | _]
             } = Upload.get_headers(locales: ["es"], translations: false)
    end

    test "returns headers grouped by required with translations" do
      assert %{
               required: ["name_es", "name_en", "domain_external_id"],
               update_required: ["id"],
               ignored: ["domain_name" | _]
             } = Upload.get_headers(locales: ["es", "en"], translations: true)
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

    # Add fake message to set english as active language
    CacheHelpers.put_i18n_messages("en", [
      %{message_id: "foo", definition: "bar"}
    ])
  end

  describe "audit: file upload with auto_publish events" do
    setup [:set_mox_from_context]

    test "file upload with auto_publish creates update and publish events with event_via='file'" do
      TdCache.Redix.del!(TdCache.Audit.stream())
      IndexWorkerMock.clear()

      claims = build(:claims, role: "admin")

      %{id: template_id} =
        Templates.create_template(%{
          id: 0,
          name: "term",
          label: "term",
          scope: "test",
          content: [
            %{
              "name" => "group",
              "fields" => [
                %{
                  "cardinality" => "1",
                  "default" => %{"value" => "", "origin" => "default"},
                  "label" => "critical term",
                  "name" => "critical",
                  "type" => "string",
                  "values" => %{"fixed" => ["Yes", "No"]}
                },
                %{
                  "cardinality" => "+",
                  "label" => "Role",
                  "name" => "role",
                  "type" => "user"
                },
                %{
                  "cardinality" => "+",
                  "label" => "Description",
                  "name" => "description",
                  "type" => "string"
                },
                %{
                  "cardinality" => "?",
                  "default" => %{"value" => "", "origin" => "default"},
                  "label" => "Number",
                  "name" => "input_integer",
                  "type" => "integer",
                  "widget" => "number",
                  "values" => nil
                },
                %{
                  "cardinality" => "?",
                  "default" => %{"value" => "", "origin" => "default"},
                  "label" => "Number",
                  "name" => "input_float",
                  "type" => "float",
                  "widget" => "number",
                  "values" => nil
                },
                %{
                  "cardinality" => "*",
                  "default" => %{"origin" => "default", "value" => ""},
                  "label" => "URL",
                  "name" => "input_url",
                  "type" => "url",
                  "widget" => "pair_list",
                  "values" => nil
                }
              ]
            }
          ]
        })

      on_exit(fn -> Templates.delete(template_id) end)

      CacheHelpers.put_active_locales(~w(en es))
      on_exit(fn -> TdCache.Redix.del!("i18n:locales:*") end)

      domain = insert(:domain, external_id: "domain")
      concept = insert(:business_concept, domain: domain, type: "term", id: 1_000)

      %{id: version_id, business_concept_id: business_concept_id} =
        insert(:business_concept_version,
          name: "original name",
          status: "published",
          business_concept: concept,
          in_progress: false,
          version: 1,
          content: %{
            "critical" => %{"origin" => "user", "value" => "Yes"},
            "description" => %{"origin" => "user", "value" => ["test"]},
            "input_float" => %{"origin" => "user", "value" => 12.5},
            "input_integer" => %{"origin" => "user", "value" => 12},
            "input_url" => %{
              "origin" => "user",
              "value" => [
                %{"url_name" => "com", "url_value" => "www.com.com"},
                %{"url_name" => "", "url_value" => "www.net.net"},
                %{"url_name" => "", "url_value" => "www.org.org"}
              ]
            },
            "role" => %{"origin" => "user", "value" => ["Role"]}
          }
        )

      insert(:i18n_content,
        business_concept_version_id: version_id,
        name: "nombre original",
        content: %{"description" => %{"value" => ["versionado"], "origin" => "user"}},
        lang: "es"
      )

      business_concept_upload = %{path: "test/fixtures/upload_version_on_content_update.xlsx"}

      Process.put(:event_via, "file")

      assert %{errors: [], created: [], updated: [_updated_id]} =
               Upload.bulk_upload(
                 business_concept_upload,
                 claims,
                 lang: "en",
                 auto_publish: true
               )

      assert {:ok, events} =
               TdCache.Redix.Stream.read(:redix, TdCache.Audit.stream(), transform: true)

      concept_events =
        Enum.filter(events, fn
          %{resource_id: resource_id, resource_type: "concept"} ->
            "#{resource_id}" == "#{business_concept_id}"

          _ ->
            false
        end)

      assert length(concept_events) >= 2

      assert Enum.all?(concept_events, fn %{payload: payload} ->
               decoded = Jason.decode!(payload)
               decoded["event_via"] == "file"
             end)

      update_event =
        Enum.find(concept_events, fn %{event: event} ->
          event in ["update_concept", "update_concept_draft"]
        end)

      assert update_event != nil

      update_payload = Jason.decode!(update_event.payload)
      assert update_payload["event_via"] == "file"
      assert Map.has_key?(update_payload, "content")

      assert update_payload["content"] == %{}

      publish_event =
        Enum.find(concept_events, fn %{event: event} ->
          event == "concept_published"
        end)

      assert publish_event != nil

      publish_payload = Jason.decode!(publish_event.payload)
      assert publish_payload["event_via"] == "file"
    end
  end

  describe "audit: payload" do
    setup [:set_mox_from_context]

    test "audit: correct diff when updating draft concept via upload" do
      TdCache.Redix.del!(TdCache.Audit.stream())
      IndexWorkerMock.clear()

      claims = build(:claims, role: "admin")

      %{id: template_id} =
        Templates.create_template(%{
          id: 0,
          name: "term",
          label: "term",
          scope: "test",
          content: [
            %{
              "name" => "group",
              "fields" => [
                %{
                  "cardinality" => "?",
                  "name" => "field_a",
                  "label" => "field_a",
                  "type" => "string"
                },
                %{
                  "cardinality" => "?",
                  "name" => "field_b",
                  "label" => "field_b",
                  "type" => "string"
                },
                %{
                  "cardinality" => "?",
                  "name" => "field_c",
                  "label" => "field_c",
                  "type" => "string"
                },
                %{
                  "cardinality" => "?",
                  "name" => "field_d",
                  "label" => "field_d",
                  "type" => "string"
                },
                %{
                  "cardinality" => "?",
                  "name" => "field_e",
                  "label" => "field_e",
                  "type" => "string"
                }
              ]
            }
          ]
        })

      on_exit(fn -> Templates.delete(template_id) end)

      CacheHelpers.put_active_locales(~w(en))
      on_exit(fn -> TdCache.Redix.del!("i18n:locales:*") end)

      domain = insert(:domain, external_id: "domain")
      concept = insert(:business_concept, domain: domain, type: "term", id: 1_000)

      %{business_concept_id: business_concept_id} =
        insert(:business_concept_version,
          name: "audit concept",
          status: "draft",
          business_concept: concept,
          version: 1,
          content: %{
            "field_a" => %{"origin" => "user", "value" => "old"},
            "field_b" => %{"origin" => "user", "value" => "old"},
            "field_c" => %{"origin" => "user", "value" => "old"},
            "field_d" => %{"origin" => "user", "value" => "old"}
          }
        )

      business_concept_upload = %{path: "test/fixtures/audit_payload_content.xlsx"}

      Process.put(:event_via, "file")

      Upload.bulk_upload(
        business_concept_upload,
        claims,
        lang: "en",
        auto_publish: false
      )

      {:ok, events} =
        TdCache.Redix.Stream.read(:redix, TdCache.Audit.stream(), transform: true)

      concept_events =
        Enum.filter(events, fn
          %{resource_id: resource_id, resource_type: "concept"} ->
            "#{resource_id}" == "#{business_concept_id}"

          _ ->
            false
        end)

      update_event =
        Enum.find(concept_events, fn %{event: event} ->
          event in ["update_concept", "update_concept_draft"]
        end)

      update_payload = Jason.decode!(update_event.payload)

      content = update_payload["content"]

      assert content["changed"] == %{"field_a" => "new", "field_c" => ""}
      assert content["added"] == %{"field_e" => "new"}
    end

    test "audit: correct diff when versioning published concept via upload" do
      TdCache.Redix.del!(TdCache.Audit.stream())
      IndexWorkerMock.clear()

      claims = build(:claims, role: "admin")

      %{id: template_id} =
        Templates.create_template(%{
          id: 0,
          name: "term",
          label: "term",
          scope: "test",
          content: [
            %{
              "name" => "group",
              "fields" => [
                %{
                  "cardinality" => "?",
                  "name" => "field_a",
                  "label" => "field_a",
                  "type" => "string"
                },
                %{
                  "cardinality" => "?",
                  "name" => "field_b",
                  "label" => "field_b",
                  "type" => "string"
                },
                %{
                  "cardinality" => "?",
                  "name" => "field_c",
                  "label" => "field_c",
                  "type" => "string"
                },
                %{
                  "cardinality" => "?",
                  "name" => "field_d",
                  "label" => "field_d",
                  "type" => "string"
                },
                %{
                  "cardinality" => "?",
                  "name" => "field_e",
                  "label" => "field_e",
                  "type" => "string"
                }
              ]
            }
          ]
        })

      on_exit(fn -> Templates.delete(template_id) end)

      CacheHelpers.put_active_locales(~w(en))
      on_exit(fn -> TdCache.Redix.del!("i18n:locales:*") end)

      domain = insert(:domain, external_id: "domain")
      concept = insert(:business_concept, domain: domain, type: "term", id: 1_000)

      %{business_concept_id: business_concept_id} =
        insert(:business_concept_version,
          name: "Audit Concept",
          status: "published",
          business_concept: concept,
          version: 1,
          content: %{
            "field_a" => %{"origin" => "user", "value" => "old"},
            "field_b" => %{"origin" => "user", "value" => "old"},
            "field_c" => %{"origin" => "user", "value" => "old"},
            "field_d" => %{"origin" => "user", "value" => "old"}
          }
        )

      business_concept_upload = %{path: "test/fixtures/audit_payload_content.xlsx"}

      Process.put(:event_via, "file")

      Upload.bulk_upload(
        business_concept_upload,
        claims,
        lang: "en",
        auto_publish: false
      )

      {:ok, events} =
        TdCache.Redix.Stream.read(:redix, TdCache.Audit.stream(), transform: true)

      concept_events =
        Enum.filter(events, fn
          %{resource_id: resource_id, resource_type: "concept"} ->
            "#{resource_id}" == "#{business_concept_id}"

          _ ->
            false
        end)

      update_event =
        Enum.find(concept_events, fn %{event: event} ->
          event in ["update_concept", "update_concept_draft"]
        end)

      update_payload = Jason.decode!(update_event.payload)

      content = update_payload["content"]

      assert content["changed"] == %{"field_a" => "new", "field_c" => ""}
      assert content["added"] == %{"field_e" => "new"}
    end
  end
end
