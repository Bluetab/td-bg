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
      domain_ext_id = "domain_ext_id"
      domain_name = "Domain Name"
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
          "domain" => %{"external_id" => domain_ext_id, "name" => domain_name},
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
             id;current_version_id;name;domain_external_id;domain_name;status;completeness;last_change_at;inserted_at;#{field_name};domain_inside_note_field\r
             #{concept_id};#{concept_version_id};#{name};#{domain_ext_id};#{domain_name};#{status};100.0;#{last_change_at};#{inserted_at};#{field_value};domain_inside_note_1_external_id|domain_inside_note_2_external_id\r
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
      domain_ext_id = "domain_ext_id"
      domain_name = "domain_name"
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
          "domain" => %{"external_id" => domain_ext_id, "name" => domain_name},
          "content" => %{field_name => field_value},
          "status" => status,
          "inserted_at" => inserted_at,
          "last_change_at" => last_change_at
        }
      ]

      csv = Download.to_csv(concepts, @lang, @concept_url_schema)

      assert csv == """
             id;current_version_id;name;domain_external_id;domain_name;status;completeness;last_change_at;inserted_at;link_to_concept;#{field_name}\r
             #{business_concept_id};#{business_concept_version_id};#{name};#{domain_ext_id};#{domain_name};#{status};100.0;#{last_change_at};#{inserted_at};https://test.io/concepts/#{business_concept_id}/versions/#{business_concept_version_id};#{field_value}\r
             """
    end

    test "to_csv/2 return business concepts non-dynamic content when related template does not exist" do
      template = @template_name
      field_name = "field_name"

      name = "concept_name"
      domain_ext_id = "domain_ext_id"
      domain_name = "Domain Name"
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
          "domain" => %{"external_id" => domain_ext_id, "name" => domain_name},
          "content" => %{field_name => field_value},
          "status" => status,
          "inserted_at" => inserted_at,
          "last_change_at" => last_change_at
        }
      ]

      csv = Download.to_csv(concepts, @lang)

      assert csv == """
             id;current_version_id;name;domain_external_id;domain_name;status;completeness;last_change_at;inserted_at\r
             #{concept_id};#{concept_version_id};#{name};#{domain_ext_id};#{domain_name};#{status};0.0;#{last_change_at};#{inserted_at}\r
             """
    end

    test "to_csv/2 return business concepts non-dynamic content when related template does not exist with url" do
      template = @template_name
      field_name = "field_name"

      business_concept_id = 123
      business_concept_version_id = 456
      name = "concept_name"
      domain_ext_id = "domain_ext_id"
      domain_name = "Domain Name"
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
          "domain" => %{"external_id" => domain_ext_id, "name" => domain_name},
          "content" => %{field_name => field_value},
          "status" => status,
          "inserted_at" => inserted_at,
          "last_change_at" => last_change_at
        }
      ]

      csv = Download.to_csv(concepts, @lang, @concept_url_schema)

      assert csv == """
             id;current_version_id;name;domain_external_id;domain_name;status;completeness;last_change_at;inserted_at;link_to_concept\r
             #{business_concept_id};#{business_concept_version_id};#{name};#{domain_ext_id};#{domain_name};#{status};0.0;#{last_change_at};#{inserted_at};https://test.io/concepts/123/versions/456\r
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
      domain_ext_id = "domain_ext_id"
      domain_name = "Domain Name"
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
          "domain" => %{"external_id" => domain_ext_id, "name" => domain_name},
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

      url_fields = "[com] (www.com.com)|[net] (www.net.net)"
      key_value_fields = "First Element|Second Element"

      csv = Download.to_csv(concepts, @lang)
      [headers, content] = csv |> String.split("\r\n") |> Enum.filter(&(&1 != ""))

      assert headers ==
               "id;current_version_id;name;domain_external_id;domain_name;status;completeness;last_change_at;inserted_at;#{url_field};#{key_value_field}"

      assert content ==
               "#{concept_id};#{concept_version_id};#{name};#{domain_ext_id};#{domain_name};#{status};100.0;#{last_change_at};#{inserted_at};#{url_fields};#{key_value_fields}"
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
      domain_ext_id = "domain_ext_id"
      domain_name = "Domain Name"
      status = "draft"
      inserted_at = "2018-05-05"
      last_change_at = "2018-05-06"

      concepts = [
        %{
          "business_concept_id" => business_concept_id,
          "id" => business_concept_version_id,
          "name" => name,
          "template" => %{"name" => template},
          "domain" => %{"external_id" => domain_ext_id, "name" => domain_name},
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

      url_fields = "[com] (www.com.com)|[net] (www.net.net)"
      key_value_fields = "First Element|Second Element"

      csv = Download.to_csv(concepts, @lang, @concept_url_schema)
      [headers, content] = csv |> String.split("\r\n") |> Enum.filter(&(&1 != ""))

      assert headers ==
               "id;current_version_id;name;domain_external_id;domain_name;status;completeness;last_change_at;inserted_at;link_to_concept;#{url_field};#{key_value_field}"

      assert content ==
               "#{business_concept_id};#{business_concept_version_id};#{name};#{domain_ext_id};#{domain_name};#{status};100.0;#{last_change_at};#{inserted_at};https://test.io/concepts/123/versions/456;#{url_fields};#{key_value_fields}"
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
      domain_ext_id = "domain_ext_id"
      domain_name = "Domain Name"
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
          "domain" => %{"external_id" => domain_ext_id, "name" => domain_name},
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
               "id;current_version_id;name;domain_external_id;domain_name;status;completeness;last_change_at;inserted_at;field1;field2;field3"

      assert content ==
               "#{concept_id};#{concept_version_id};#{name};#{domain_ext_id};#{domain_name};#{status};66.67;#{last_change_at};#{inserted_at};value;value;"
    end

    @tag template: [
           %{
             "name" => "group",
             "fields" => [
               %{"name" => "field1", "type" => "string", "label" => "field1"},
               %{"name" => "field2", "type" => "string", "label" => "field2"},
               %{"name" => "field3", "type" => "string", "label" => "field3"},
               %{
                 "cardinality" => "?",
                 "default" => %{"origin" => "default", "value" => ""},
                 "label" => "field4",
                 "name" => "field4",
                 "type" => "string",
                 "values" => %{"fixed" => ["op1", "op2", "op3"]},
                 "widget" => "dropdown"
               },
               %{
                 "cardinality" => "?",
                 "default" => %{"origin" => "default", "value" => ""},
                 "label" => "field5",
                 "name" => "field5",
                 "type" => "string",
                 "values" => %{
                   "switch" => %{
                     "on" => "field4",
                     "values" => %{
                       "opt1" => ["opt1-1", "opt1-2", "opt1-3"],
                       "opt2" => ["opt2-1", "opt2-2", "opt2-3"],
                       "opt3" => ["opt3-1", "opt3-2", "opt3-3"]
                     }
                   }
                 },
                 "widget" => "dropdown"
               }
             ]
           }
         ]
    test "to_csv/2 return calculated completeness with is visible fields" do
      template = @template_name

      name = "concept_name"
      domain_ext_id = "domain_ext_id"
      domain_name = "Domain Name"
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
          "domain" => %{"external_id" => domain_ext_id, "name" => domain_name},
          "content" => %{
            "field1" => "",
            "field2" => "",
            "field3" => "",
            "field4" => "",
            "field5" => ""
          },
          "status" => status,
          "inserted_at" => inserted_at,
          "last_change_at" => last_change_at
        }
      ]

      csv = Download.to_csv(concepts, @lang)
      [headers, content] = csv |> String.split("\r\n") |> Enum.filter(&(&1 != ""))

      assert headers ==
               "id;current_version_id;name;domain_external_id;domain_name;status;completeness;last_change_at;inserted_at;field1;field2;field3;field4;field5"

      assert content ==
               "#{concept_id};#{concept_version_id};#{name};#{domain_ext_id};#{domain_name};#{status};0.0;#{last_change_at};#{inserted_at};;;;;"
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
      domain_ext_id = "domain_ext_id"
      domain_name = "Domain Name"
      status = "draft"
      inserted_at = "2018-05-05"
      last_change_at = "2018-05-06"

      concepts = [
        %{
          "business_concept_id" => business_concept_id,
          "id" => business_concept_version_id,
          "name" => name,
          "template" => %{"name" => template},
          "domain" => %{"external_id" => domain_ext_id, "name" => domain_name},
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
               "id;current_version_id;name;domain_external_id;domain_name;status;completeness;last_change_at;inserted_at;link_to_concept;field1;field2;field3"

      assert content ==
               "#{business_concept_id};#{business_concept_version_id};#{name};#{domain_ext_id};#{domain_name};#{status};66.67;#{last_change_at};#{inserted_at};https://test.io/concepts/123/versions/456;value;value;"
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
      domain_ext_id = "domain_ext_id"
      domain_name = "Domain Name"
      status = "Borrador"
      inserted_at = "2018-05-05"
      last_change_at = "2018-05-06"

      concepts = [
        %{
          "business_concept_id" => business_concept_id,
          "id" => business_concept_version_id,
          "name" => name,
          "template" => %{"name" => template},
          "domain" => %{"external_id" => domain_ext_id, "name" => domain_name},
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
               "id;current_version_id;name;domain_external_id;domain_name;status;completeness;last_change_at;inserted_at;link_to_concept;field1_name;field2_name;field3_name"

      assert content ==
               "#{business_concept_id};#{business_concept_version_id};#{name};#{domain_ext_id};#{domain_name};#{status};66.67;#{last_change_at};#{inserted_at};https://test.io/concepts/123/versions/456;Valor 1;value;"
    end

    @tag template: [
           %{
             "name" => "group",
             "fields" => [
               %{
                 "cardinality" => "?",
                 "default" => %{"value" => "", "origin" => "default"},
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
                 "default" => %{"value" => "", "origin" => "user"},
                 "label" => "label_i18n_test_no_translate",
                 "name" => "i18n_test_no_translate",
                 "type" => "string",
                 "values" => nil,
                 "widget" => "string"
               },
               %{
                 "cardinality" => "?",
                 "default" => %{"value" => "", "origin" => "user"},
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
                 "default" => %{"value" => "", "origin" => "default"},
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
      domain_ext_id = "domain_ext_id"
      domain_name = "Domain Name"
      status = "draft"
      inserted_at = "2018-05-05"
      last_change_at = "2018-05-06"

      concepts = [
        %{
          "business_concept_id" => business_concept_id,
          "id" => business_concept_version_id,
          "name" => name,
          "template" => %{"name" => template},
          "domain" => %{"external_id" => domain_ext_id, "name" => domain_name},
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
               "id;current_version_id;name;domain_external_id;domain_name;status;completeness;last_change_at;inserted_at;link_to_concept;i18n_test.dropdown.fixed;i18n_test_no_translate;i18n_test.radio.fixed;i18n_test.checkbox.fixed_tuple"

      assert content ==
               "#{business_concept_id};#{business_concept_version_id};#{name};#{domain_ext_id};#{domain_name};draft;100.0;#{last_change_at};#{inserted_at};https://test.io/concepts/123/versions/456;Pera;Test no translate;Platano;Pera|Platano"
    end

    @tag template: [
           %{
             "name" => "group",
             "fields" => [
               %{"name" => "url_field", "type" => "url", "label" => "Url"}
             ]
           }
         ]

    test "to_xlsx/2 return formatted links with names" do
      template = @template_name

      url_field = "url_field"

      business_concept_id = 123
      business_concept_version_id = 456
      name = "concept_name"
      domain_ext_id = "domain_ext_id"
      domain_name = "Domain Name"
      status = "draft"
      inserted_at = "2018-05-05"
      last_change_at = "2018-05-06"

      concepts = [
        %{
          "business_concept_id" => business_concept_id,
          "id" => business_concept_version_id,
          "name" => name,
          "template" => %{"name" => template},
          "domain" => %{"external_id" => domain_ext_id, "name" => domain_name},
          "content" => %{
            url_field => [
              %{"url_name" => "com", "url_value" => "www.com.com"},
              %{"url_name" => "", "url_value" => "www.net.net"},
              %{"url_value" => "www.org.org"}
            ]
          },
          "status" => status,
          "inserted_at" => inserted_at,
          "last_change_at" => last_change_at
        }
      ]

      url_fields = "[com] (www.com.com)|www.net.net|www.org.org"

      csv = Download.to_csv(concepts, @lang, @concept_url_schema)
      [headers, content] = csv |> String.split("\r\n") |> Enum.filter(&(&1 != ""))

      assert headers ==
               "id;current_version_id;name;domain_external_id;domain_name;status;completeness;last_change_at;inserted_at;link_to_concept;url_field"

      assert content ==
               "#{business_concept_id};#{business_concept_version_id};#{name};#{domain_ext_id};#{domain_name};draft;100.0;#{last_change_at};#{inserted_at};https://test.io/concepts/123/versions/456;#{url_fields}"
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
      domain_ext_id = "domain_ext_id"
      domain_name = "Domain Name"
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
          "domain" => %{"external_id" => domain_ext_id, "name" => domain_name},
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
          ["id", {:bg_color, "#ffe994"}],
          "current_version_id",
          ["name", {:bg_color, "#ffd428"}],
          ["domain_external_id", {:bg_color, "#ffd428"}],
          "domain_name",
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
          domain_ext_id,
          domain_name,
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
      domain_ext_id = "domain_ext_id"
      domain_name = "Domain Name"
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
          "domain" => %{"external_id" => domain_ext_id, "name" => domain_name},
          "content" => %{field_name => field_value},
          "status" => status,
          "inserted_at" => inserted_at,
          "last_change_at" => last_change_at
        }
      ]

      rows = [
        [
          ["id", {:bg_color, "#ffe994"}],
          "current_version_id",
          ["name", {:bg_color, "#ffd428"}],
          ["domain_external_id", {:bg_color, "#ffd428"}],
          "domain_name",
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
          domain_ext_id,
          domain_name,
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

    @tag template: [
           %{
             "name" => "group",
             "fields" => [
               %{
                 "name" => "field_name",
                 "type" => "table",
                 "label" => "field_label",
                 "values" => %{
                   "table_columns" => [
                     %{"name" => "colA", "mandatory" => true},
                     %{"name" => "colB", "mandatory" => true}
                   ]
                 }
               }
             ]
           }
         ]
    test "to_xlsx/2 handles table fields" do
      template = @template_name
      field_name = "field_name"
      business_concept_id = 123
      business_concept_version_id = 456
      name = "concept_name"
      domain_ext_id = "domain_ext_id"
      domain_name = "Domain Name"
      field_value = "colA;colB\nvalueA1;valueB1\nvalueA2;valueB2"
      status = "draft"
      inserted_at = "2018-05-05"
      last_change_at = "2018-05-06"

      concepts = [
        %{
          "business_concept_id" => business_concept_id,
          "id" => business_concept_version_id,
          "name" => name,
          "template" => %{"name" => template},
          "domain" => %{"external_id" => domain_ext_id, "name" => domain_name},
          "content" => %{
            "field_name" => %{
              "origin" => "file",
              "value" => [
                %{"colA" => "valueA1", "colB" => "valueB1"},
                %{"colA" => "valueA2", "colB" => "valueB2"}
              ]
            }
          },
          "status" => status,
          "inserted_at" => inserted_at,
          "last_change_at" => last_change_at
        }
      ]

      rows = [
        [
          ["id", {:bg_color, "#ffe994"}],
          "current_version_id",
          ["name", {:bg_color, "#ffd428"}],
          ["domain_external_id", {:bg_color, "#ffd428"}],
          "domain_name",
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
          domain_ext_id,
          domain_name,
          status,
          100.0,
          last_change_at,
          inserted_at,
          "https://test.io/concepts/#{business_concept_id}/versions/#{business_concept_version_id}",
          [field_value, {:align_vertical, :top}]
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
                 "name" => "field_name",
                 "type" => "table",
                 "label" => "field_label",
                 "values" => %{
                   "table_columns" => [
                     %{"name" => "colA", "mandatory" => true},
                     %{"name" => "colB", "mandatory" => true}
                   ]
                 }
               }
             ]
           }
         ]
    test "to_xlsx/2 return enty table field if only headers" do
      template = @template_name
      field_name = "field_name"
      business_concept_id = 123
      business_concept_version_id = 456
      name = "concept_name"
      domain_ext_id = "domain_ext_id"
      domain_name = "Domain Name"
      field_value = ""
      status = "draft"
      inserted_at = "2018-05-05"
      last_change_at = "2018-05-06"

      concepts = [
        %{
          "business_concept_id" => business_concept_id,
          "id" => business_concept_version_id,
          "name" => name,
          "template" => %{"name" => template},
          "domain" => %{"external_id" => domain_ext_id, "name" => domain_name},
          "content" => %{
            "field_name" => %{
              "origin" => "file",
              "value" => []
            }
          },
          "status" => status,
          "inserted_at" => inserted_at,
          "last_change_at" => last_change_at
        }
      ]

      rows = [
        [
          ["id", {:bg_color, "#ffe994"}],
          "current_version_id",
          ["name", {:bg_color, "#ffd428"}],
          ["domain_external_id", {:bg_color, "#ffd428"}],
          "domain_name",
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
          domain_ext_id,
          domain_name,
          status,
          0.0,
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
      domain_ext_id = "domain_ext_id"
      domain_name = "Domain Name"
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
          "domain" => %{"external_id" => domain_ext_id, "name" => domain_name},
          "content" => %{field_name => field_value},
          "status" => status,
          "inserted_at" => inserted_at,
          "last_change_at" => last_change_at
        }
      ]

      rows = [
        [
          ["id", {:bg_color, "#ffe994"}],
          "current_version_id",
          ["name", {:bg_color, "#ffd428"}],
          ["domain_external_id", {:bg_color, "#ffd428"}],
          "domain_name",
          "status",
          "completeness",
          "last_change_at",
          "inserted_at"
        ],
        [
          concept_id,
          concept_version_id,
          name,
          domain_ext_id,
          domain_name,
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
      domain_ext_id = "domain_ext_id"
      domain_name = "Domain Name"
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
          "domain" => %{"external_id" => domain_ext_id, "name" => domain_name},
          "content" => %{field_name => field_value},
          "status" => status,
          "inserted_at" => inserted_at,
          "last_change_at" => last_change_at
        }
      ]

      rows = [
        [
          ["id", {:bg_color, "#ffe994"}],
          "current_version_id",
          ["name", {:bg_color, "#ffd428"}],
          ["domain_external_id", {:bg_color, "#ffd428"}],
          "domain_name",
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
          domain_ext_id,
          domain_name,
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
      domain_ext_id = "domain_ext_id"
      domain_name = "Domain Name"
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
          "domain" => %{"external_id" => domain_ext_id, "name" => domain_name},
          "content" => %{
            url_field => [
              %{"url_name" => "com", "url_value" => "www.com.com"},
              %{"url_name" => "", "url_value" => "www.net.net"},
              %{"url_value" => "www.org.org"}
            ],
            key_value_field => ["1", "2"]
          },
          "status" => status,
          "inserted_at" => inserted_at,
          "last_change_at" => last_change_at
        }
      ]

      url_fields = "[com] (www.com.com)|www.net.net|www.org.org"
      key_value_fields = "First Element|Second Element"

      rows = [
        [
          ["id", {:bg_color, "#ffe994"}],
          "current_version_id",
          ["name", {:bg_color, "#ffd428"}],
          ["domain_external_id", {:bg_color, "#ffd428"}],
          "domain_name",
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
          domain_ext_id,
          domain_name,
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
      domain_ext_id = "domain_ext_id"
      domain_name = "Domain Name"
      status = "draft"
      inserted_at = "2018-05-05"
      last_change_at = "2018-05-06"

      concepts = [
        %{
          "business_concept_id" => business_concept_id,
          "id" => business_concept_version_id,
          "name" => name,
          "template" => %{"name" => template},
          "domain" => %{"external_id" => domain_ext_id, "name" => domain_name},
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

      url_fields = "[com] (www.com.com)|[net] (www.net.net)"
      key_value_fields = "First Element|Second Element"

      rows = [
        [
          ["id", {:bg_color, "#ffe994"}],
          "current_version_id",
          ["name", {:bg_color, "#ffd428"}],
          ["domain_external_id", {:bg_color, "#ffd428"}],
          "domain_name",
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
          domain_ext_id,
          domain_name,
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
               %{"name" => "url_field", "type" => "url", "label" => "Url"}
             ]
           }
         ]

    test "to_xlsx/2 return formatted links with names" do
      template = @template_name

      url_field = "url_field"

      business_concept_id = 123
      business_concept_version_id = 456
      name = "concept_name"
      domain_ext_id = "domain_ext_id"
      domain_name = "Domain Name"
      status = "draft"
      inserted_at = "2018-05-05"
      last_change_at = "2018-05-06"

      concepts = [
        %{
          "business_concept_id" => business_concept_id,
          "id" => business_concept_version_id,
          "name" => name,
          "template" => %{"name" => template},
          "domain" => %{"external_id" => domain_ext_id, "name" => domain_name},
          "content" => %{
            url_field => [
              %{"url_name" => "com", "url_value" => "www.com.com"},
              %{"url_name" => "", "url_value" => "www.net.net"},
              %{"url_value" => "www.org.org"}
            ]
          },
          "status" => status,
          "inserted_at" => inserted_at,
          "last_change_at" => last_change_at
        }
      ]

      url_fields = "[com] (www.com.com)|www.net.net|www.org.org"

      rows = [
        [
          ["id", {:bg_color, "#ffe994"}],
          "current_version_id",
          ["name", {:bg_color, "#ffd428"}],
          ["domain_external_id", {:bg_color, "#ffd428"}],
          "domain_name",
          "status",
          "completeness",
          "last_change_at",
          "inserted_at",
          "link_to_concept",
          url_field
        ],
        [
          business_concept_id,
          business_concept_version_id,
          name,
          domain_ext_id,
          domain_name,
          status,
          100.0,
          last_change_at,
          inserted_at,
          "https://test.io/concepts/123/versions/456",
          url_fields
        ]
      ]

      assert %Workbook{
               sheets: [
                 %Sheet{
                   name: ^template,
                   rows: ^rows
                 }
               ]
             } =
               Download.to_xlsx(concepts, @lang, @concept_url_schema)
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
      domain_ext_id = "domain_ext_id"
      domain_name = "Domain Name"
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
          "domain" => %{"external_id" => domain_ext_id, "name" => domain_name},
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
          ["id", {:bg_color, "#ffe994"}],
          "current_version_id",
          ["name", {:bg_color, "#ffd428"}],
          ["domain_external_id", {:bg_color, "#ffd428"}],
          "domain_name",
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
          domain_ext_id,
          domain_name,
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
      domain_ext_id = "domain_ext_id"
      domain_name = "Domain Name"
      status = "draft"
      inserted_at = "2018-05-05"
      last_change_at = "2018-05-06"

      concepts = [
        %{
          "business_concept_id" => business_concept_id,
          "id" => business_concept_version_id,
          "name" => name,
          "template" => %{"name" => template},
          "domain" => %{"external_id" => domain_ext_id, "name" => domain_name},
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
          ["id", {:bg_color, "#ffe994"}],
          "current_version_id",
          ["name", {:bg_color, "#ffd428"}],
          ["domain_external_id", {:bg_color, "#ffd428"}],
          "domain_name",
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
          domain_ext_id,
          domain_name,
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
               %{"name" => "field1", "type" => "string", "label" => "field1"},
               %{"name" => "field2", "type" => "string", "label" => "field2"},
               %{"name" => "field3", "type" => "string", "label" => "field3"},
               %{
                 "cardinality" => "?",
                 "default" => %{"origin" => "default", "value" => ""},
                 "label" => "field4",
                 "name" => "field4",
                 "type" => "string",
                 "values" => %{"fixed" => ["op1", "op2", "op3"]},
                 "widget" => "dropdown"
               },
               %{
                 "cardinality" => "?",
                 "default" => %{"origin" => "default", "value" => ""},
                 "label" => "field5",
                 "name" => "field5",
                 "type" => "string",
                 "values" => %{
                   "switch" => %{
                     "on" => "field4",
                     "values" => %{
                       "opt1" => ["opt1-1", "opt1-2", "opt1-3"],
                       "opt2" => ["opt2-1", "opt2-2", "opt2-3"],
                       "opt3" => ["opt3-1", "opt3-2", "opt3-3"]
                     }
                   }
                 },
                 "widget" => "dropdown"
               }
             ]
           }
         ]

    test "to_xlsx/2 return calculated completeness with is visible" do
      template = @template_name

      business_concept_id = 123
      business_concept_version_id = 456
      name = "concept_name"
      domain_ext_id = "domain_ext_id"
      domain_name = "Domain Name"
      status = "draft"
      inserted_at = "2018-05-05"
      last_change_at = "2018-05-06"

      concepts = [
        %{
          "business_concept_id" => business_concept_id,
          "id" => business_concept_version_id,
          "name" => name,
          "template" => %{"name" => template},
          "domain" => %{"external_id" => domain_ext_id, "name" => domain_name},
          "content" => %{
            "field1" => "",
            "field2" => "",
            "field3" => "",
            "field4" => "",
            "field5" => ""
          },
          "status" => status,
          "inserted_at" => inserted_at,
          "last_change_at" => last_change_at
        }
      ]

      rows = [
        [
          ["id", {:bg_color, "#ffe994"}],
          "current_version_id",
          ["name", {:bg_color, "#ffd428"}],
          ["domain_external_id", {:bg_color, "#ffd428"}],
          "domain_name",
          "status",
          "completeness",
          "last_change_at",
          "inserted_at",
          "link_to_concept",
          "field1",
          "field2",
          "field3",
          "field4",
          "field5"
        ],
        [
          business_concept_id,
          business_concept_version_id,
          name,
          domain_ext_id,
          domain_name,
          status,
          0.0,
          last_change_at,
          inserted_at,
          "https://test.io/concepts/123/versions/456",
          "",
          "",
          "",
          "",
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
      domain_ext_id = "domain_ext_id"
      domain_name = "Domain Name"
      status = "Borrador"
      inserted_at = "2018-05-05"
      last_change_at = "2018-05-06"

      concepts = [
        %{
          "business_concept_id" => business_concept_id,
          "id" => business_concept_version_id,
          "name" => name,
          "template" => %{"name" => template},
          "domain" => %{"external_id" => domain_ext_id, "name" => domain_name},
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
          ["id", {:bg_color, "#ffe994"}],
          "current_version_id",
          ["name", {:bg_color, "#ffd428"}],
          ["domain_external_id", {:bg_color, "#ffd428"}],
          "domain_name",
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
          domain_ext_id,
          domain_name,
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
                 "default" => %{"value" => "", "origin" => "default"},
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
                 "default" => %{"value" => "", "origin" => "default"},
                 "label" => "label_i18n_test_no_translate",
                 "name" => "i18n_test_no_translate",
                 "type" => "string",
                 "values" => nil,
                 "widget" => "string"
               },
               %{
                 "cardinality" => "?",
                 "default" => %{"value" => "", "origin" => "user"},
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
                 "default" => %{"value" => "", "origin" => "user"},
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
      domain_ext_id = "domain_ext_id"
      domain_name = "Domain Name"
      status = "draft"
      inserted_at = "2018-05-05"
      last_change_at = "2018-05-06"

      concepts = [
        %{
          "business_concept_id" => business_concept_id,
          "id" => business_concept_version_id,
          "name" => name,
          "template" => %{"name" => template},
          "domain" => %{"external_id" => domain_ext_id, "name" => domain_name},
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
          ["id", {:bg_color, "#ffe994"}],
          "current_version_id",
          ["name", {:bg_color, "#ffd428"}],
          ["domain_external_id", {:bg_color, "#ffd428"}],
          "domain_name",
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
          domain_ext_id,
          domain_name,
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
