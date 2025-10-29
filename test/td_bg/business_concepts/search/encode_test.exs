defmodule TdBg.BusinessConcepts.Search.EncodeTest do
  use TdBg.DataCase

  import Mox

  alias Elasticsearch.Document

  @template_name "some_type"

  @content [
    %{
      "name" => "Basic",
      "fields" => [
        %{
          "name" => "df_description",
          "type" => "enriched_text",
          "label" => "Descripción",
          "values" => nil,
          "widget" => "enriched_text",
          "cardinality" => "?"
        },
        %{
          "name" => "basic_list",
          "type" => "string",
          "label" => "Basic List",
          "values" => %{"fixed" => ["1", "2", "3", "4"]},
          "widget" => "dropdown",
          "cardinality" => "1"
        },
        %{
          "name" => "basic_switch",
          "type" => "string",
          "label" => "Basic Switch",
          "values" => %{
            "switch" => %{
              "on" => "basic_list",
              "values" => %{
                "1" => ["a", "b"],
                "2" => ["c", "d"]
              }
            }
          },
          "widget" => "dropdown",
          "cardinality" => "?"
        },
        %{
          "name" => "default_dependency",
          "type" => "string",
          "label" => "Dependent field with default values",
          "values" => %{
            "switch" => %{
              "on" => "basic_list",
              "values" => %{
                "1" => ["1.1", "1..2", "1.3", "1.4", "1.5"],
                "2" => ["2.1", "2.2", "2.3"],
                "3" => ["3.1", "3.2", "3.3", "3.4", "3.5"]
              }
            }
          },
          "widget" => "dropdown",
          "default" => %{
            "value" => %{"1" => "1.1", "2" => "2.2", "3" => "3.4"},
            "origin" => "default"
          },
          "cardinality" => "?"
        },
        %{
          "name" => "Identificador",
          "type" => "string",
          "label" => "Identificador",
          "values" => nil,
          "widget" => "identifier",
          "cardinality" => "0"
        },
        %{
          "name" => "multiple_values",
          "type" => "string",
          "label" => "Multiple values",
          "values" => %{"fixed" => ["v-1", "v-2", "v-3"]},
          "widget" => "checkbox",
          "cardinality" => "*"
        },
        %{
          "name" => "user1",
          "type" => "user",
          "label" => "User 1",
          "values" => %{"role_users" => "Data Owner", "processed_users" => []},
          "widget" => "dropdown",
          "cardinality" => "?"
        },
        %{
          "name" => "User Group",
          "type" => "user_group",
          "label" => "User Group",
          "values" => %{
            "role_groups" => "Data Owner",
            "processed_users" => [],
            "processed_groups" => []
          },
          "widget" => "dropdown",
          "cardinality" => "?"
        },
        %{
          "name" => "text_area",
          "type" => "string",
          "label" => "Text area",
          "values" => "",
          "widget" => "string",
          "cardinality" => "?"
        },
        %{
          "name" => "enriched_text",
          "type" => "enriched_text",
          "label" => "Enriched text",
          "values" => "",
          "widget" => "enriched_text",
          "cardinality" => "?"
        },
        %{
          "name" => "text_input",
          "type" => "string",
          "label" => "Text input",
          "values" => "",
          "widget" => "string",
          "cardinality" => "1"
        },
        %{
          "name" => "empty test",
          "type" => "string",
          "label" => "empty test",
          "values" => %{"fixed" => ["a", "s", "d"]},
          "widget" => "dropdown",
          "cardinality" => "?"
        },
        %{
          "name" => "Hierarchie2",
          "type" => "hierarchy",
          "label" => "Hierarchie",
          "values" => %{"hierarchy" => %{"id" => 4, "min_depth" => "2"}},
          "widget" => "dropdown",
          "cardinality" => "?"
        },
        %{
          "name" => "table",
          "cardinality" => "*",
          "type" => "dynamic_table",
          "widget" => "dynamic_table",
          "values" => %{
            "table_columns" => [
              %{"name" => "col1", "type" => "string", "cardinality" => "1"},
              %{"name" => "col2", "type" => "string", "cardinality" => "+"},
              %{
                "cardinality" => "*",
                "name" => "col3",
                "type" => "user_group",
                "values" => %{"processed_users" => [], "role_groups" => "Data Owner"},
                "widget" => "dropdown"
              }
            ]
          }
        }
      ]
    }
  ]
  @df_template %{
    id: System.unique_integer([:positive]),
    label: "df_test",
    name: @template_name,
    scope: "bg",
    content: @content
  }

  setup do
    CacheHelpers.insert_template(@df_template)

    stub(MockClusterHandler, :call, fn :ai, TdAi.Indices, :exists_enabled?, [] ->
      {:ok, true}
    end)

    template =
      build(:template,
        scope: "bg",
        content: [
          build(:template_group,
            fields: [
              build(:template_field, name: "domain", type: "domain", cardinality: "?"),
              build(:template_field, name: "domains", type: "domain", cardinality: "*")
            ]
          )
        ]
      )

    [template: CacheHelpers.insert_template(template)]
  end

  describe "Elasticsearch.Document.encode/2" do
    test "encodes a BusinessConceptVersion for indexing", %{template: template} do
      content = %{
        "domain" => %{"value" => 1, "origin" => "user"},
        "domains" => %{"value" => [1, 2], "origin" => "user"}
      }

      bcv =
        insert(:business_concept_version, content: content, type: template.name)
        |> Repo.preload(business_concept: :shared_to)

      assert %{content: encoded_content} = Document.encode(bcv)

      assert encoded_content == %{"domain" => 1, "domains" => [1, 2]}
    end

    test "encodes the latest last_changes" do
      %{id: last_user_id} = CacheHelpers.insert_user()
      %{id: old_user_id} = CacheHelpers.insert_user()

      last_datetime = DateTime.utc_now()
      old_datetime = DateTime.add(last_datetime, -5, :day)

      bcv =
        insert(:business_concept_version,
          last_change_at: last_datetime,
          last_change_by: last_user_id,
          business_concept:
            build(:business_concept, last_change_at: old_datetime, last_change_by: old_user_id)
        )
        |> Repo.preload(business_concept: :shared_to)

      assert %{
               last_change_at: ^last_datetime,
               last_change_by: %{id: ^last_user_id}
             } =
               Document.encode(bcv)

      bcv =
        insert(:business_concept_version,
          last_change_at: old_datetime,
          last_change_by: old_user_id,
          business_concept:
            build(:business_concept, last_change_at: last_datetime, last_change_by: last_user_id)
        )
        |> Repo.preload(business_concept: :shared_to)

      assert %{
               last_change_at: ^last_datetime,
               last_change_by: %{id: ^last_user_id}
             } = Document.encode(bcv)
    end

    test "encodes only translatable fields in i18n with default translation values" do
      busines_concept_content = %{
        "df_description" => %{
          "value" => %{
            "document" => %{
              "nodes" => [
                %{
                  "nodes" => [
                    %{
                      "marks" => [],
                      "object" => "text",
                      "text" => "enrich text"
                    }
                  ],
                  "object" => "block",
                  "type" => "paragraph"
                }
              ]
            }
          },
          "origin" => "user"
        },
        "basic_list" => %{"value" => "1", "origin" => "user"},
        "Identificador" => %{"value" => "foo", "origin" => "user"},
        "text_area" => %{"value" => "default_foo", "origin" => "user"},
        "table" => %{
          "value" => [
            %{
              "col1" => %{"value" => "value1", "origin" => "user"},
              "col2" => %{"value" => ["value2"], "origin" => "user"},
              "col3" => %{"value" => ["John Doe"], "origin" => "user"}
            }
          ],
          "origin" => "user"
        }
      }

      %{id: bcv_id} =
        bcv =
        :business_concept_version
        |> insert(
          content: busines_concept_content,
          name: "Concept Name",
          type: @template_name
        )
        |> Repo.preload(business_concept: :shared_to)

      i18n_content = %{
        "text_input" => %{"value" => "foo_translatable", "origin" => "user"},
        "text_area" => %{"value" => "bar_translatable", "origin" => "user"}
      }

      i18n_name = "i18n_name"

      insert(:i18n_content,
        business_concept_version_id: bcv_id,
        content: i18n_content,
        lang: "es",
        name: i18n_name
      )

      assert %{name_es: ^i18n_name, content: content} = Document.encode(bcv)

      assert %{
               "Identificador" => "foo",
               "basic_list" => "1",
               "df_description" => "enrich text",
               "df_description_es" => "enrich text",
               "text_area" => "default_foo",
               "text_area_es" => "bar_translatable",
               "text_input_es" => "foo_translatable",
               "Hierarchie2" => "",
               "User Group" => "",
               "basic_switch" => "",
               "default_dependency" => "1.1",
               "multiple_values" => [""],
               "text_input" => "",
               "user1" => "",
               "empty test" => "",
               "enriched_text" => "",
               "enriched_text_es" => "",
               "table" => [%{"col1" => "value1", "col2" => ["value2"], "col3" => ["John Doe"]}]
             } == content
    end

    test "encodes only translatable fields in i18n without default translation values" do
      busines_concept_content = %{
        "df_description" => %{
          "value" => %{
            "document" => %{
              "nodes" => [
                %{
                  "nodes" => [
                    %{
                      "marks" => [],
                      "object" => "text",
                      "text" => "enrich text"
                    }
                  ],
                  "object" => "block",
                  "type" => "paragraph"
                }
              ]
            }
          },
          "origin" => "user"
        },
        "basic_list" => %{"value" => "1", "origin" => "user"},
        "text_input" => %{"value" => "original_foo", "origin" => "user"}
      }

      i18n_content = %{
        "text_input" => %{"value" => "foo_translatable", "origin" => "user"},
        "text_area" => %{"value" => nil, "origin" => "user"}
      }

      %{id: bcv_id} =
        bcv =
        :business_concept_version
        |> insert(
          content: busines_concept_content,
          name: "Concept Name",
          type: @template_name
        )
        |> Repo.preload(business_concept: :shared_to)

      i18n_name = "i18n_name"

      insert(:i18n_content,
        business_concept_version_id: bcv_id,
        content: i18n_content,
        lang: "es",
        name: i18n_name
      )

      assert %{name_es: ^i18n_name, content: content} =
               Document.encode(bcv)

      assert %{
               "basic_list" => "1",
               "text_input" => "original_foo",
               "text_input_es" => "foo_translatable",
               "text_area" => "",
               "text_area_es" => "",
               "df_description" => "enrich text",
               "df_description_es" => "enrich text",
               "empty test" => "",
               "Hierarchie2" => "",
               "User Group" => "",
               "basic_switch" => "",
               "enriched_text" => "",
               "enriched_text_es" => "",
               "default_dependency" => "1.1",
               "multiple_values" => [""],
               "user1" => ""
             } == content
    end
  end

  test "when encodes empty translatable fields, assigns the default value" do
    busines_concept_content = %{
      "df_description" => %{
        "value" => %{
          "document" => %{
            "nodes" => [
              %{
                "nodes" => [
                  %{
                    "marks" => [],
                    "object" => "text",
                    "text" => "enrich text"
                  }
                ],
                "object" => "block",
                "type" => "paragraph"
              }
            ]
          }
        },
        "origin" => "user"
      },
      "basic_list" => %{"value" => "1", "origin" => "user"},
      "text_input" => %{"value" => "original_foo", "origin" => "user"},
      "text_area" => %{"value" => "original_bar", "origin" => "user"}
    }

    i18n_content = %{
      "text_input" => %{"value" => "", "origin" => "user"},
      "text_area" => %{"value" => nil, "origin" => "user"}
    }

    %{id: bcv_id} =
      bcv =
      :business_concept_version
      |> insert(
        content: busines_concept_content,
        name: "Concept Name",
        type: @template_name
      )
      |> Repo.preload(business_concept: :shared_to)

    i18n_name = "i18n_name"

    insert(:i18n_content,
      business_concept_version_id: bcv_id,
      content: i18n_content,
      lang: "es",
      name: i18n_name
    )

    assert %{name_es: ^i18n_name, content: content} =
             Document.encode(bcv)

    assert %{
             "basic_list" => "1",
             "empty test" => "",
             "text_input" => "original_foo",
             "text_input_es" => "original_foo",
             "text_area" => "original_bar",
             "text_area_es" => "original_bar",
             "df_description" => "enrich text",
             "df_description_es" => "enrich text",
             "Hierarchie2" => "",
             "User Group" => "",
             "basic_switch" => "",
             "enriched_text" => "",
             "enriched_text_es" => "",
             "default_dependency" => "1.1",
             "multiple_values" => [""],
             "user1" => ""
           } == content
  end
end
