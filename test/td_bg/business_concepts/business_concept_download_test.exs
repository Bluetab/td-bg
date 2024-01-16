defmodule TdBg.BusinessConceptDownloadTests do
  use TdBg.DataCase

  alias Elixlsx.{Sheet, Workbook}
  alias TdBg.BusinessConcept.Download

  @template_name "download_template"
  @concept_url_schema "https://test.io/concepts/:business_concept_id/versions/:id"
  @lang "es"

  setup context do
    case context[:template] do
      nil ->
        :ok

      content ->
        Templates.create_template(%{
          id: 0,
          name: @template_name,
          label: "label",
          scope: "test",
          content: content
        })
    end

    :ok
  end

  describe "business_concept_download to_csv" do
    @tag template: [
           %{
             "name" => "group",
             "fields" => [
               %{"name" => "field_name", "type" => "list", "label" => "field_label"},
               %{
                 "name" => "domain_inside_note_field",
                 "type" => "domain",
                 "label" => "domain_inside_note_field_label",
                 "cardinality" => "*"
               }
             ]
           }
         ]
    test "to_csv/2 return cvs content to download" do
      template = @template_name
      field_name = "field_name"

      name = "concept_name"
      domain = "domain_name"
      field_value = "field_value"
      status = "draft"
      inserted_at = "2018-05-05"
      last_change_at = "2018-05-06"

      %{id: domain_inside_note_1_id} =
        CacheHelpers.insert_domain(%{
          name: "domain_inside_note_1_name",
          external_id: "domain_inside_note_1_external_id"
        })

      %{id: domain_inside_note_2_id} =
        CacheHelpers.insert_domain(%{
          name: "domain_inside_note_2_name",
          external_id: "domain_inside_note_2_external_id"
        })

      concept_id = 1
      concept_version_id = 2

      concepts = [
        %{
          "business_concept_id" => concept_id,
          "id" => concept_version_id,
          "name" => name,
          "template" => %{"name" => template},
          "domain" => %{"external_id" => domain},
          "content" => %{
            field_name => field_value,
            "domain_inside_note_field" => [domain_inside_note_1_id, domain_inside_note_2_id]
          },
          "status" => status,
          "inserted_at" => inserted_at,
          "last_change_at" => last_change_at
        }
      ]

      csv = Download.to_csv(concepts, @lang)

      assert csv == """
             id;current_version_id;name;domain;status;completeness;last_change_at;inserted_at;#{field_name};domain_inside_note_field\r
             #{concept_id};#{concept_version_id};#{name};#{domain};#{status};100.0;#{last_change_at};#{inserted_at};#{field_value};domain_inside_note_1_external_id|domain_inside_note_2_external_id\r
             """
    end

    @tag template: [
           %{
             "name" => "group",
             "fields" => [%{"name" => "field_name", "type" => "list", "label" => "field_label"}]
           }
         ]
    test "to_csv/2 return cvs content to download with url" do
      template = @template_name
      field_name = "field_name"

      business_concept_id = 123
      business_concept_version_id = 456
      name = "concept_name"
      domain = "domain_name"
      field_value = "field_value"
      status = "draft"
      inserted_at = "2018-05-05"
      last_change_at = "2018-05-06"

      concepts = [
        %{
          "business_concept_id" => business_concept_id,
          "id" => business_concept_version_id,
          "name" => name,
          "template" => %{"name" => template},
          "domain" => %{"external_id" => domain},
          "content" => %{field_name => field_value},
          "status" => status,
          "inserted_at" => inserted_at,
          "last_change_at" => last_change_at
        }
      ]

      csv = Download.to_csv(concepts, @lang, @concept_url_schema)

      assert csv == """
             id;current_version_id;name;domain;status;completeness;last_change_at;inserted_at;link_to_concept;#{field_name}\r
             #{business_concept_id};#{business_concept_version_id};#{name};#{domain};#{status};100.0;#{last_change_at};#{inserted_at};https://test.io/concepts/#{business_concept_id}/versions/#{business_concept_version_id};#{field_value}\r
             """
    end

    test "to_csv/2 return business concepts non-dynamic content when related template does not exist" do
      template = @template_name
      field_name = "field_name"

      name = "concept_name"
      domain = "domain_name"
      field_value = "field_value"
      status = "draft"
      inserted_at = "2018-05-05"
      last_change_at = "2018-05-06"

      concept_id = 1
      concept_version_id = 2

      concepts = [
        %{
          "business_concept_id" => concept_id,
          "id" => concept_version_id,
          "name" => name,
          "template" => %{"name" => template},
          "domain" => %{"external_id" => domain},
          "content" => %{field_name => field_value},
          "status" => status,
          "inserted_at" => inserted_at,
          "last_change_at" => last_change_at
        }
      ]

      csv = Download.to_csv(concepts, @lang)

      assert csv == """
             id;current_version_id;name;domain;status;completeness;last_change_at;inserted_at\r
             #{concept_id};#{concept_version_id};#{name};#{domain};#{status};0.0;#{last_change_at};#{inserted_at}\r
             """
    end

    test "to_csv/2 return business concepts non-dynamic content when related template does not exist with url" do
      template = @template_name
      field_name = "field_name"

      business_concept_id = 123
      business_concept_version_id = 456
      name = "concept_name"
      domain = "domain_name"
      field_value = "field_value"
      status = "draft"
      inserted_at = "2018-05-05"
      last_change_at = "2018-05-06"

      concepts = [
        %{
          "business_concept_id" => business_concept_id,
          "id" => business_concept_version_id,
          "name" => name,
          "template" => %{"name" => template},
          "domain" => %{"external_id" => domain},
          "content" => %{field_name => field_value},
          "status" => status,
          "inserted_at" => inserted_at,
          "last_change_at" => last_change_at
        }
      ]

      csv = Download.to_csv(concepts, @lang, @concept_url_schema)

      assert csv == """
             id;current_version_id;name;domain;status;completeness;last_change_at;inserted_at;link_to_concept\r
             #{business_concept_id};#{business_concept_version_id};#{name};#{domain};#{status};0.0;#{last_change_at};#{inserted_at};https://test.io/concepts/123/versions/456\r
             """
    end

    @tag template: [
           %{
             "name" => "group",
             "fields" => [
               %{"name" => "url_field", "type" => "url", "label" => "Url"},
               %{
                 "name" => "key_value",
                 "type" => "string",
                 "label" => "Key And Value",
                 "values" => %{
                   "fixed_tuple" => [
                     %{"text" => "First Element", "value" => "1"},
                     %{"text" => "Second Element", "value" => "2"}
                   ]
                 }
               }
             ]
           }
         ]
    test "to_csv/2 return formatted fields in concepts with dynamic content" do
      template = @template_name

      url_field = "url_field"

      key_value_field = "key_value"

      name = "concept_name"
      domain = "domain_name"
      status = "draft"
      inserted_at = "2018-05-05"
      last_change_at = "2018-05-06"

      concept_id = 1
      concept_version_id = 2

      concepts = [
        %{
          "id" => concept_version_id,
          "business_concept_id" => concept_id,
          "name" => name,
          "template" => %{"name" => template},
          "domain" => %{"external_id" => domain},
          "content" => %{
            url_field => [
              %{"url_name" => "com", "url_value" => "www.com.com"},
              %{"url_name" => "net", "url_value" => "www.net.net"}
            ],
            key_value_field => ["1", "2"]
          },
          "status" => status,
          "inserted_at" => inserted_at,
          "last_change_at" => last_change_at
        }
      ]

      url_fields = "www.com.com|www.net.net"
      key_value_fields = "First Element|Second Element"

      csv = Download.to_csv(concepts, @lang)
      [headers, content] = csv |> String.split("\r\n") |> Enum.filter(&(&1 != ""))

      assert headers ==
               "id;current_version_id;name;domain;status;completeness;last_change_at;inserted_at;#{url_field};#{key_value_field}"

      assert content ==
               "#{concept_id};#{concept_version_id};#{name};#{domain};#{status};100.0;#{last_change_at};#{inserted_at};#{url_fields};#{key_value_fields}"
    end

    @tag template: [
           %{
             "name" => "group",
             "fields" => [
               %{"name" => "url_field", "type" => "url", "label" => "Url"},
               %{
                 "name" => "key_value",
                 "type" => "string",
                 "label" => "Key And Value",
                 "values" => %{
                   "fixed_tuple" => [
                     %{"text" => "First Element", "value" => "1"},
                     %{"text" => "Second Element", "value" => "2"}
                   ]
                 }
               }
             ]
           }
         ]
    test "to_csv/2 return formatted fields in concepts with dynamic content with link" do
      template = @template_name

      url_field = "url_field"

      key_value_field = "key_value"

      business_concept_id = 123
      business_concept_version_id = 456
      name = "concept_name"
      domain = "domain_name"
      status = "draft"
      inserted_at = "2018-05-05"
      last_change_at = "2018-05-06"

      concepts = [
        %{
          "business_concept_id" => business_concept_id,
          "id" => business_concept_version_id,
          "name" => name,
          "template" => %{"name" => template},
          "domain" => %{"external_id" => domain},
          "content" => %{
            url_field => [
              %{"url_name" => "com", "url_value" => "www.com.com"},
              %{"url_name" => "net", "url_value" => "www.net.net"}
            ],
            key_value_field => ["1", "2"]
          },
          "status" => status,
          "inserted_at" => inserted_at,
          "last_change_at" => last_change_at
        }
      ]

      url_fields = "www.com.com|www.net.net"
      key_value_fields = "First Element|Second Element"

      csv = Download.to_csv(concepts, @lang, @concept_url_schema)
      [headers, content] = csv |> String.split("\r\n") |> Enum.filter(&(&1 != ""))

      assert headers ==
               "id;current_version_id;name;domain;status;completeness;last_change_at;inserted_at;link_to_concept;#{url_field};#{key_value_field}"

      assert content ==
               "#{business_concept_id};#{business_concept_version_id};#{name};#{domain};#{status};100.0;#{last_change_at};#{inserted_at};https://test.io/concepts/123/versions/456;#{url_fields};#{key_value_fields}"
    end

    @tag template: [
           %{
             "name" => "group",
             "fields" => [
               %{"name" => "field1", "type" => "string", "label" => "field1"},
               %{"name" => "field2", "type" => "string", "label" => "field2"},
               %{"name" => "field3", "type" => "string", "label" => "field3"}
             ]
           }
         ]
    test "to_csv/2 return calculated completeness" do
      template = @template_name

      name = "concept_name"
      domain = "domain_name"
      status = "draft"
      inserted_at = "2018-05-05"
      last_change_at = "2018-05-06"

      concept_id = 1
      concept_version_id = 2

      concepts = [
        %{
          "business_concept_id" => concept_id,
          "id" => concept_version_id,
          "name" => name,
          "template" => %{"name" => template},
          "domain" => %{"external_id" => domain},
          "content" => %{
            "field1" => "value",
            "field2" => "value"
          },
          "status" => status,
          "inserted_at" => inserted_at,
          "last_change_at" => last_change_at
        }
      ]

      csv = Download.to_csv(concepts, @lang)
      [headers, content] = csv |> String.split("\r\n") |> Enum.filter(&(&1 != ""))

      assert headers ==
               "id;current_version_id;name;domain;status;completeness;last_change_at;inserted_at;field1;field2;field3"

      assert content ==
               "#{concept_id};#{concept_version_id};#{name};#{domain};#{status};66.67;#{last_change_at};#{inserted_at};value;value;"
    end

    @tag template: [
           %{
             "name" => "group",
             "fields" => [
               %{"name" => "field1", "type" => "string", "label" => "field1"},
               %{"name" => "field2", "type" => "string", "label" => "field2"},
               %{"name" => "field3", "type" => "string", "label" => "field3"}
             ]
           }
         ]
    test "to_csv/2 return calculated completeness with url" do
      template = @template_name

      business_concept_id = 123
      business_concept_version_id = 456
      name = "concept_name"
      domain = "domain_name"
      status = "draft"
      inserted_at = "2018-05-05"
      last_change_at = "2018-05-06"

      concepts = [
        %{
          "business_concept_id" => business_concept_id,
          "id" => business_concept_version_id,
          "name" => name,
          "template" => %{"name" => template},
          "domain" => %{"external_id" => domain},
          "content" => %{
            "field1" => "value",
            "field2" => "value"
          },
          "status" => status,
          "inserted_at" => inserted_at,
          "last_change_at" => last_change_at
        }
      ]

      csv = Download.to_csv(concepts, @lang, @concept_url_schema)
      [headers, content] = csv |> String.split("\r\n") |> Enum.filter(&(&1 != ""))

      assert headers ==
               "id;current_version_id;name;domain;status;completeness;last_change_at;inserted_at;link_to_concept;field1;field2;field3"

      assert content ==
               "#{business_concept_id};#{business_concept_version_id};#{name};#{domain};#{status};66.67;#{last_change_at};#{inserted_at};https://test.io/concepts/123/versions/456;value;value;"
    end

    @tag template: [
           %{
             "name" => "group",
             "fields" => [
               %{
                 "name" => "field1_name",
                 "type" => "string",
                 "label" => "field1_label",
                 "values" => %{"fixed" => ["value1", "value2"]}
               },
               %{"name" => "field2_name", "type" => "string", "label" => "field2_label"},
               %{"name" => "field3_name", "type" => "string", "label" => "field3_label"}
             ]
           }
         ]
    test "to_csv/2 return calculated completeness with url and translates column and data" do
      template = @template_name

      business_concept_id = 123
      business_concept_version_id = 456
      name = "concept_name"
      domain = "domain_name"
      status = "draft"
      inserted_at = "2018-05-05"
      last_change_at = "2018-05-06"

      concepts = [
        %{
          "business_concept_id" => business_concept_id,
          "id" => business_concept_version_id,
          "name" => name,
          "template" => %{"name" => template},
          "domain" => %{"external_id" => domain},
          "content" => %{
            "field1_name" => "value1",
            "field2_name" => "value"
          },
          "status" => status,
          "inserted_at" => inserted_at,
          "last_change_at" => last_change_at
        }
      ]

      CacheHelpers.put_i18n_messages(@lang, [
        %{message_id: "concepts.status.#{status}", definition: "Borrador"},
        %{message_id: "fields.field1_label.value1", definition: "Valor 1"},
        %{message_id: "fields.field1_label.value2", definition: "Valor 2"}
      ])

      csv = Download.to_csv(concepts, @lang, @concept_url_schema)
      [headers, content] = csv |> String.split("\r\n") |> Enum.filter(&(&1 != ""))

      assert headers ==
               "id;current_version_id;name;domain;status;completeness;last_change_at;inserted_at;link_to_concept;field1_name;field2_name;field3_name"

      assert content ==
               "#{business_concept_id};#{business_concept_version_id};#{name};#{domain};draft;66.67;#{last_change_at};#{inserted_at};https://test.io/concepts/123/versions/456;Valor 1;value;"
    end

    @tag template: [
           %{
             "name" => "group",
             "fields" => [
               %{
                 "cardinality" => "?",
                 "default" => "",
                 "label" => "label_i18n_test.dropdown.fixed",
                 "name" => "i18n_test.dropdown.fixed",
                 "subscribable" => false,
                 "type" => "string",
                 "values" => %{
                   "fixed" => [
                     "pear",
                     "banana"
                   ]
                 },
                 "widget" => "dropdown"
               },
               %{
                 "cardinality" => "?",
                 "default" => "",
                 "label" => "label_i18n_test_no_translate",
                 "name" => "i18n_test_no_translate",
                 "type" => "string",
                 "values" => nil,
                 "widget" => "string"
               },
               %{
                 "cardinality" => "?",
                 "default" => "",
                 "label" => "label_i18n_test.radio.fixed",
                 "name" => "i18n_test.radio.fixed",
                 "subscribable" => false,
                 "type" => "string",
                 "values" => %{
                   "fixed" => [
                     "pear",
                     "banana"
                   ]
                 },
                 "widget" => "radio"
               },
               %{
                 "cardinality" => "*",
                 "default" => "",
                 "label" => "label_i18n_test.checkbox.fixed_tuple",
                 "name" => "i18n_test.checkbox.fixed_tuple",
                 "subscribable" => false,
                 "type" => "string",
                 "values" => %{
                   "fixed_tuple" => [
                     %{
                       "text" => "pear",
                       "value" => "option_1"
                     },
                     %{
                       "text" => "banana",
                       "value" => "option_2"
                     }
                   ]
                 },
                 "widget" => "checkbox"
               }
             ]
           }
         ]
    test "to_editable_csv return editable csv translated" do
      template = @template_name

      CacheHelpers.put_i18n_messages("es", [
        %{message_id: "fields.label_i18n_test.dropdown.fixed", definition: "Dropdown Fijo"},
        %{message_id: "fields.label_i18n_test.dropdown.fixed.pear", definition: "Pera"},
        %{message_id: "fields.label_i18n_test.dropdown.fixed.banana", definition: "Platano"},
        %{message_id: "fields.label_i18n_test.radio.fixed", definition: "Radio Fijo"},
        %{message_id: "fields.label_i18n_test.radio.fixed.pear", definition: "Pera"},
        %{message_id: "fields.label_i18n_test.radio.fixed.banana", definition: "Platano"},
        %{
          message_id: "fields.label_i18n_test.checkbox.fixed_tuple",
          definition: "Checkbox Tupla Fija"
        },
        %{message_id: "fields.label_i18n_test.checkbox.fixed_tuple.pear", definition: "Pera"},
        %{message_id: "fields.label_i18n_test.checkbox.fixed_tuple.banana", definition: "Platano"}
      ])

      business_concept_id = 123
      business_concept_version_id = 456
      name = "concept_name"
      domain = "domain_name"
      status = "draft"
      inserted_at = "2018-05-05"
      last_change_at = "2018-05-06"

      concepts = [
        %{
          "business_concept_id" => business_concept_id,
          "id" => business_concept_version_id,
          "name" => name,
          "template" => %{"name" => template},
          "domain" => %{"external_id" => domain},
          "content" => %{
            "i18n_test.dropdown.fixed" => "pear",
            "i18n_test_no_translate" => "Test no translate",
            "i18n_test.radio.fixed" => "banana",
            "i18n_test.checkbox.fixed_tuple" => ["option_1", "option_2"]
          },
          "status" => status,
          "inserted_at" => inserted_at,
          "last_change_at" => last_change_at
        }
      ]

      csv = Download.to_csv(concepts, @lang, @concept_url_schema)
      [headers, content] = csv |> String.split("\r\n") |> Enum.filter(&(&1 != ""))

      assert headers ==
               "id;current_version_id;name;domain;status;completeness;last_change_at;inserted_at;link_to_concept;i18n_test.dropdown.fixed;i18n_test_no_translate;i18n_test.radio.fixed;i18n_test.checkbox.fixed_tuple"

      assert content ==
               "#{business_concept_id};#{business_concept_version_id};#{name};#{domain};draft;100.0;#{last_change_at};#{inserted_at};https://test.io/concepts/123/versions/456;Pera;Test no translate;Platano;Pera|Platano"
    end
  end

  describe "business_concept_download to_xlsx" do
    @tag template: [
           %{
             "name" => "group",
             "fields" => [
               %{"name" => "field_name", "type" => "list", "label" => "field_label"},
               %{
                 "name" => "domain_inside_note_field",
                 "type" => "domain",
                 "label" => "domain_inside_note_field_label",
                 "cardinality" => "*"
               }
             ]
           }
         ]
    test "to_xlsx/2 return cvs content to download" do
      template = @template_name
      field_name = "field_name"

      name = "concept_name"
      domain = "domain_name"
      field_value = "field_value"
      status = "draft"
      inserted_at = "2018-05-05"
      last_change_at = "2018-05-06"

      %{id: domain_inside_note_1_id} =
        CacheHelpers.insert_domain(%{
          name: "domain_inside_note_1_name",
          external_id: "domain_inside_note_1_external_id"
        })

      %{id: domain_inside_note_2_id} =
        CacheHelpers.insert_domain(%{
          name: "domain_inside_note_2_name",
          external_id: "domain_inside_note_2_external_id"
        })

      concept_id = 1
      concept_version_id = 2

      concepts = [
        %{
          "business_concept_id" => concept_id,
          "id" => concept_version_id,
          "name" => name,
          "template" => %{"name" => template},
          "domain" => %{"external_id" => domain},
          "content" => %{
            field_name => field_value,
            "domain_inside_note_field" => [domain_inside_note_1_id, domain_inside_note_2_id]
          },
          "status" => status,
          "inserted_at" => inserted_at,
          "last_change_at" => last_change_at
        }
      ]

      rows = [
        [
          "id",
          "current_version_id",
          "name",
          "domain",
          "status",
          "completeness",
          "last_change_at",
          "inserted_at",
          field_name,
          "domain_inside_note_field"
        ],
        [
          concept_id,
          concept_version_id,
          name,
          domain,
          status,
          100.0,
          last_change_at,
          inserted_at,
          field_value,
          "domain_inside_note_1_external_id|domain_inside_note_2_external_id"
        ]
      ]

      assert %Workbook{
               sheets: [
                 %Sheet{
                   name: ^template,
                   rows: ^rows
                 }
               ]
             } = Download.to_xlsx(concepts, @lang)
    end

    @tag template: [
           %{
             "name" => "group",
             "fields" => [%{"name" => "field_name", "type" => "list", "label" => "field_label"}]
           }
         ]
    test "to_xlsx/2 return cvs content to download with url" do
      template = @template_name
      field_name = "field_name"

      business_concept_id = 123
      business_concept_version_id = 456
      name = "concept_name"
      domain = "domain_name"
      field_value = "field_value"
      status = "draft"
      inserted_at = "2018-05-05"
      last_change_at = "2018-05-06"

      concepts = [
        %{
          "business_concept_id" => business_concept_id,
          "id" => business_concept_version_id,
          "name" => name,
          "template" => %{"name" => template},
          "domain" => %{"external_id" => domain},
          "content" => %{field_name => field_value},
          "status" => status,
          "inserted_at" => inserted_at,
          "last_change_at" => last_change_at
        }
      ]

      rows = [
        [
          "id",
          "current_version_id",
          "name",
          "domain",
          "status",
          "completeness",
          "last_change_at",
          "inserted_at",
          "link_to_concept",
          field_name
        ],
        [
          business_concept_id,
          business_concept_version_id,
          name,
          domain,
          status,
          100.0,
          last_change_at,
          inserted_at,
          "https://test.io/concepts/#{business_concept_id}/versions/#{business_concept_version_id}",
          field_value
        ]
      ]

      assert %Workbook{
               sheets: [
                 %Sheet{
                   name: ^template,
                   rows: ^rows
                 }
               ]
             } = Download.to_xlsx(concepts, @lang, @concept_url_schema)
    end

    test "to_xlsx/2 return business concepts non-dynamic content when related template does not exist" do
      template = @template_name
      field_name = "field_name"

      name = "concept_name"
      domain = "domain_name"
      field_value = "field_value"
      status = "draft"
      inserted_at = "2018-05-05"
      last_change_at = "2018-05-06"

      concept_id = 1
      concept_version_id = 2

      concepts = [
        %{
          "business_concept_id" => concept_id,
          "id" => concept_version_id,
          "name" => name,
          "template" => %{"name" => template},
          "domain" => %{"external_id" => domain},
          "content" => %{field_name => field_value},
          "status" => status,
          "inserted_at" => inserted_at,
          "last_change_at" => last_change_at
        }
      ]

      rows = [
        [
          "id",
          "current_version_id",
          "name",
          "domain",
          "status",
          "completeness",
          "last_change_at",
          "inserted_at"
        ],
        [
          concept_id,
          concept_version_id,
          name,
          domain,
          status,
          0.0,
          last_change_at,
          inserted_at
        ]
      ]

      assert %Workbook{
               sheets: [
                 %Sheet{
                   name: ^template,
                   rows: ^rows
                 }
               ]
             } = Download.to_xlsx(concepts, @lang)
    end

    test "to_xlsx/2 return business concepts non-dynamic content when related template does not exist with url" do
      template = @template_name
      field_name = "field_name"

      business_concept_id = 123
      business_concept_version_id = 456
      name = "concept_name"
      domain = "domain_name"
      field_value = "field_value"
      status = "draft"
      inserted_at = "2018-05-05"
      last_change_at = "2018-05-06"

      concepts = [
        %{
          "business_concept_id" => business_concept_id,
          "id" => business_concept_version_id,
          "name" => name,
          "template" => %{"name" => template},
          "domain" => %{"external_id" => domain},
          "content" => %{field_name => field_value},
          "status" => status,
          "inserted_at" => inserted_at,
          "last_change_at" => last_change_at
        }
      ]

      rows = [
        [
          "id",
          "current_version_id",
          "name",
          "domain",
          "status",
          "completeness",
          "last_change_at",
          "inserted_at",
          "link_to_concept"
        ],
        [
          business_concept_id,
          business_concept_version_id,
          name,
          domain,
          status,
          0.0,
          last_change_at,
          inserted_at,
          "https://test.io/concepts/123/versions/456"
        ]
      ]

      assert %Workbook{
               sheets: [
                 %Sheet{
                   name: ^template,
                   rows: ^rows
                 }
               ]
             } = Download.to_xlsx(concepts, @lang, @concept_url_schema)
    end

    @tag template: [
           %{
             "name" => "group",
             "fields" => [
               %{"name" => "url_field", "type" => "url", "label" => "Url"},
               %{
                 "name" => "key_value",
                 "type" => "string",
                 "label" => "Key And Value",
                 "values" => %{
                   "fixed_tuple" => [
                     %{"text" => "First Element", "value" => "1"},
                     %{"text" => "Second Element", "value" => "2"}
                   ]
                 }
               }
             ]
           }
         ]
    test "to_xlsx/2 return formatted fields in concepts with dynamic content" do
      template = @template_name

      url_field = "url_field"

      key_value_field = "key_value"

      name = "concept_name"
      domain = "domain_name"
      status = "draft"
      inserted_at = "2018-05-05"
      last_change_at = "2018-05-06"

      concept_id = 1
      concept_version_id = 2

      concepts = [
        %{
          "business_concept_id" => concept_id,
          "id" => concept_version_id,
          "name" => name,
          "template" => %{"name" => template},
          "domain" => %{"external_id" => domain},
          "content" => %{
            url_field => [
              %{"url_name" => "com", "url_value" => "www.com.com"},
              %{"url_name" => "net", "url_value" => "www.net.net"}
            ],
            key_value_field => ["1", "2"]
          },
          "status" => status,
          "inserted_at" => inserted_at,
          "last_change_at" => last_change_at
        }
      ]

      url_fields = "www.com.com|www.net.net"
      key_value_fields = "First Element|Second Element"

      rows = [
        [
          "id",
          "current_version_id",
          "name",
          "domain",
          "status",
          "completeness",
          "last_change_at",
          "inserted_at",
          url_field,
          key_value_field
        ],
        [
          concept_id,
          concept_version_id,
          name,
          domain,
          status,
          100.0,
          last_change_at,
          inserted_at,
          url_fields,
          key_value_fields
        ]
      ]

      assert %Workbook{
               sheets: [
                 %Sheet{
                   name: ^template,
                   rows: ^rows
                 }
               ]
             } = Download.to_xlsx(concepts, @lang)
    end

    @tag template: [
           %{
             "name" => "group",
             "fields" => [
               %{"name" => "url_field", "type" => "url", "label" => "Url"},
               %{
                 "name" => "key_value",
                 "type" => "string",
                 "label" => "Key And Value",
                 "values" => %{
                   "fixed_tuple" => [
                     %{"text" => "First Element", "value" => "1"},
                     %{"text" => "Second Element", "value" => "2"}
                   ]
                 }
               }
             ]
           }
         ]
    test "to_xlsx/2 return formatted fields in concepts with dynamic content with link" do
      template = @template_name

      url_field = "url_field"

      key_value_field = "key_value"

      business_concept_id = 123
      business_concept_version_id = 456
      name = "concept_name"
      domain = "domain_name"
      status = "draft"
      inserted_at = "2018-05-05"
      last_change_at = "2018-05-06"

      concepts = [
        %{
          "business_concept_id" => business_concept_id,
          "id" => business_concept_version_id,
          "name" => name,
          "template" => %{"name" => template},
          "domain" => %{"external_id" => domain},
          "content" => %{
            url_field => [
              %{"url_name" => "com", "url_value" => "www.com.com"},
              %{"url_name" => "net", "url_value" => "www.net.net"}
            ],
            key_value_field => ["1", "2"]
          },
          "status" => status,
          "inserted_at" => inserted_at,
          "last_change_at" => last_change_at
        }
      ]

      url_fields = "www.com.com|www.net.net"
      key_value_fields = "First Element|Second Element"

      rows = [
        [
          "id",
          "current_version_id",
          "name",
          "domain",
          "status",
          "completeness",
          "last_change_at",
          "inserted_at",
          "link_to_concept",
          url_field,
          key_value_field
        ],
        [
          business_concept_id,
          business_concept_version_id,
          name,
          domain,
          status,
          100.0,
          last_change_at,
          inserted_at,
          "https://test.io/concepts/123/versions/456",
          url_fields,
          key_value_fields
        ]
      ]

      assert %Workbook{
               sheets: [
                 %Sheet{
                   name: ^template,
                   rows: ^rows
                 }
               ]
             } = Download.to_xlsx(concepts, @lang, @concept_url_schema)
    end

    @tag template: [
           %{
             "name" => "group",
             "fields" => [
               %{"name" => "field1", "type" => "string", "label" => "field1"},
               %{"name" => "field2", "type" => "string", "label" => "field2"},
               %{"name" => "field3", "type" => "string", "label" => "field3"}
             ]
           }
         ]
    test "to_xlsx/2 return calculated completeness" do
      template = @template_name

      name = "concept_name"
      domain = "domain_name"
      status = "draft"
      inserted_at = "2018-05-05"
      last_change_at = "2018-05-06"

      concept_id = 1
      concept_version_id = 2

      concepts = [
        %{
          "business_concept_id" => concept_id,
          "id" => concept_version_id,
          "name" => name,
          "template" => %{"name" => template},
          "domain" => %{"external_id" => domain},
          "content" => %{
            "field1" => "value",
            "field2" => "value"
          },
          "status" => status,
          "inserted_at" => inserted_at,
          "last_change_at" => last_change_at
        }
      ]

      rows = [
        [
          "id",
          "current_version_id",
          "name",
          "domain",
          "status",
          "completeness",
          "last_change_at",
          "inserted_at",
          "field1",
          "field2",
          "field3"
        ],
        [
          concept_id,
          concept_version_id,
          name,
          domain,
          status,
          66.67,
          last_change_at,
          inserted_at,
          "value",
          "value",
          ""
        ]
      ]

      assert %Workbook{
               sheets: [
                 %Sheet{
                   name: ^template,
                   rows: ^rows
                 }
               ]
             } = Download.to_xlsx(concepts, @lang)
    end

    @tag template: [
           %{
             "name" => "group",
             "fields" => [
               %{"name" => "field1", "type" => "string", "label" => "field1"},
               %{"name" => "field2", "type" => "string", "label" => "field2"},
               %{"name" => "field3", "type" => "string", "label" => "field3"}
             ]
           }
         ]
    test "to_xlsx/2 return calculated completeness with url" do
      template = @template_name

      business_concept_id = 123
      business_concept_version_id = 456
      name = "concept_name"
      domain = "domain_name"
      status = "draft"
      inserted_at = "2018-05-05"
      last_change_at = "2018-05-06"

      concepts = [
        %{
          "business_concept_id" => business_concept_id,
          "id" => business_concept_version_id,
          "name" => name,
          "template" => %{"name" => template},
          "domain" => %{"external_id" => domain},
          "content" => %{
            "field1" => "value",
            "field2" => "value"
          },
          "status" => status,
          "inserted_at" => inserted_at,
          "last_change_at" => last_change_at
        }
      ]

      rows = [
        [
          "id",
          "current_version_id",
          "name",
          "domain",
          "status",
          "completeness",
          "last_change_at",
          "inserted_at",
          "link_to_concept",
          "field1",
          "field2",
          "field3"
        ],
        [
          business_concept_id,
          business_concept_version_id,
          name,
          domain,
          status,
          66.67,
          last_change_at,
          inserted_at,
          "https://test.io/concepts/123/versions/456",
          "value",
          "value",
          ""
        ]
      ]

      assert %Workbook{
               sheets: [
                 %Sheet{
                   name: ^template,
                   rows: ^rows
                 }
               ]
             } = Download.to_xlsx(concepts, @lang, @concept_url_schema)
    end

    @tag template: [
           %{
             "name" => "group",
             "fields" => [
               %{
                 "name" => "field1_name",
                 "type" => "string",
                 "label" => "field1_label",
                 "values" => %{"fixed" => ["value1", "value2"]}
               },
               %{"name" => "field2_name", "type" => "string", "label" => "field2_label"},
               %{"name" => "field3_name", "type" => "string", "label" => "field3_label"}
             ]
           }
         ]
    test "to_xlsx/2 return calculated completeness with url and translates column and data" do
      template = @template_name

      business_concept_id = 123
      business_concept_version_id = 456
      name = "concept_name"
      domain = "domain_name"
      status = "draft"
      inserted_at = "2018-05-05"
      last_change_at = "2018-05-06"

      concepts = [
        %{
          "business_concept_id" => business_concept_id,
          "id" => business_concept_version_id,
          "name" => name,
          "template" => %{"name" => template},
          "domain" => %{"external_id" => domain},
          "content" => %{
            "field1_name" => "value1",
            "field2_name" => "value"
          },
          "status" => status,
          "inserted_at" => inserted_at,
          "last_change_at" => last_change_at
        }
      ]

      CacheHelpers.put_i18n_messages(@lang, [
        %{message_id: "concepts.status.#{status}", definition: "Borrador"},
        %{message_id: "fields.field1_label.value1", definition: "Valor 1"},
        %{message_id: "fields.field1_label.value2", definition: "Valor 2"}
      ])

      rows = [
        [
          "id",
          "current_version_id",
          "name",
          "domain",
          "status",
          "completeness",
          "last_change_at",
          "inserted_at",
          "link_to_concept",
          "field1_name",
          "field2_name",
          "field3_name"
        ],
        [
          business_concept_id,
          business_concept_version_id,
          name,
          domain,
          status,
          66.67,
          last_change_at,
          inserted_at,
          "https://test.io/concepts/123/versions/456",
          "Valor 1",
          "value",
          ""
        ]
      ]

      assert %Workbook{
               sheets: [
                 %Sheet{
                   name: ^template,
                   rows: ^rows
                 }
               ]
             } = Download.to_xlsx(concepts, @lang, @concept_url_schema)
    end

    @tag template: [
           %{
             "name" => "group",
             "fields" => [
               %{
                 "cardinality" => "?",
                 "default" => "",
                 "label" => "label_i18n_test.dropdown.fixed",
                 "name" => "i18n_test.dropdown.fixed",
                 "subscribable" => false,
                 "type" => "string",
                 "values" => %{
                   "fixed" => [
                     "pear",
                     "banana"
                   ]
                 },
                 "widget" => "dropdown"
               },
               %{
                 "cardinality" => "?",
                 "default" => "",
                 "label" => "label_i18n_test_no_translate",
                 "name" => "i18n_test_no_translate",
                 "type" => "string",
                 "values" => nil,
                 "widget" => "string"
               },
               %{
                 "cardinality" => "?",
                 "default" => "",
                 "label" => "label_i18n_test.radio.fixed",
                 "name" => "i18n_test.radio.fixed",
                 "subscribable" => false,
                 "type" => "string",
                 "values" => %{
                   "fixed" => [
                     "pear",
                     "banana"
                   ]
                 },
                 "widget" => "radio"
               },
               %{
                 "cardinality" => "*",
                 "default" => "",
                 "label" => "label_i18n_test.checkbox.fixed_tuple",
                 "name" => "i18n_test.checkbox.fixed_tuple",
                 "subscribable" => false,
                 "type" => "string",
                 "values" => %{
                   "fixed_tuple" => [
                     %{
                       "text" => "pear",
                       "value" => "option_1"
                     },
                     %{
                       "text" => "banana",
                       "value" => "option_2"
                     }
                   ]
                 },
                 "widget" => "checkbox"
               }
             ]
           }
         ]
    test "to_editable_csv return editable csv translated" do
      template = @template_name

      CacheHelpers.put_i18n_messages("es", [
        %{message_id: "fields.label_i18n_test.dropdown.fixed", definition: "Dropdown Fijo"},
        %{message_id: "fields.label_i18n_test.dropdown.fixed.pear", definition: "Pera"},
        %{message_id: "fields.label_i18n_test.dropdown.fixed.banana", definition: "Platano"},
        %{message_id: "fields.label_i18n_test.radio.fixed", definition: "Radio Fijo"},
        %{message_id: "fields.label_i18n_test.radio.fixed.pear", definition: "Pera"},
        %{message_id: "fields.label_i18n_test.radio.fixed.banana", definition: "Platano"},
        %{
          message_id: "fields.label_i18n_test.checkbox.fixed_tuple",
          definition: "Checkbox Tupla Fija"
        },
        %{message_id: "fields.label_i18n_test.checkbox.fixed_tuple.pear", definition: "Pera"},
        %{message_id: "fields.label_i18n_test.checkbox.fixed_tuple.banana", definition: "Platano"}
      ])

      business_concept_id = 123
      business_concept_version_id = 456
      name = "concept_name"
      domain = "domain_name"
      status = "draft"
      inserted_at = "2018-05-05"
      last_change_at = "2018-05-06"

      concepts = [
        %{
          "business_concept_id" => business_concept_id,
          "id" => business_concept_version_id,
          "name" => name,
          "template" => %{"name" => template},
          "domain" => %{"external_id" => domain},
          "content" => %{
            "i18n_test.dropdown.fixed" => "pear",
            "i18n_test_no_translate" => "Test no translate",
            "i18n_test.radio.fixed" => "banana",
            "i18n_test.checkbox.fixed_tuple" => ["option_1", "option_2"]
          },
          "status" => status,
          "inserted_at" => inserted_at,
          "last_change_at" => last_change_at
        }
      ]

      rows = [
        [
          "id",
          "current_version_id",
          "name",
          "domain",
          "status",
          "completeness",
          "last_change_at",
          "inserted_at",
          "link_to_concept",
          "i18n_test.dropdown.fixed",
          "i18n_test_no_translate",
          "i18n_test.radio.fixed",
          "i18n_test.checkbox.fixed_tuple"
        ],
        [
          business_concept_id,
          business_concept_version_id,
          name,
          domain,
          status,
          100.0,
          last_change_at,
          inserted_at,
          "https://test.io/concepts/123/versions/456",
          "Pera",
          "Test no translate",
          "Platano",
          "Pera|Platano"
        ]
      ]

      assert %Workbook{
               sheets: [
                 %Sheet{
                   name: ^template,
                   rows: ^rows
                 }
               ]
             } = Download.to_xlsx(concepts, @lang, @concept_url_schema)
    end
  end
end
