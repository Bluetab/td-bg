defmodule TdBg.BusinessConceptDownloadTests do
  use TdBg.DataCase

  @template_name "download_template"
  @concept_url_schema "https://test.io/concepts/:business_concept_id/versions/:id"

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

  describe "business_concept_download" do
    alias TdBg.BusinessConcept.Download

    @tag template: [
           %{
             "name" => "group",
             "fields" => [%{"name" => "field_name", "type" => "list", "label" => "field_label"}]
           }
         ]
    test "to_csv/1 return cvs content to download" do
      template = @template_name
      field_name = "field_name"
      field_label = "field_label"

      name = "concept_name"
      description = "concept_description"
      domain = "domain_name"
      field_value = "field_value"
      status = "draft"
      inserted_at = "2018-05-05"
      last_change_at = "2018-05-06"

      concepts = [
        %{
          "name" => name,
          "description" => description,
          "template" => %{"name" => template},
          "domain" => %{"name" => domain},
          "content" => %{field_name => field_value},
          "status" => status,
          "inserted_at" => inserted_at,
          "last_change_at" => last_change_at
        }
      ]

      header_labels = %{
        "template" => "Plantilla",
        "description" => "Descripción",
        "last_change_at" => "Fecha de última modificación"
      }

      csv = Download.to_csv(concepts, header_labels)

      assert csv == """
             Plantilla;name;domain;status;Descripción;completeness;inserted_at;Fecha de última modificación;#{field_label}\r
             #{template};#{name};#{domain};#{status};#{description};100.0;#{inserted_at};#{last_change_at};#{field_value}\r
             """
    end

    @tag template: [
           %{
             "name" => "group",
             "fields" => [%{"name" => "field_name", "type" => "list", "label" => "field_label"}]
           }
         ]
    test "to_csv/1 return cvs content to download with url" do
      template = @template_name
      field_name = "field_name"
      field_label = "field_label"

      business_concept_id = 123
      business_concept_version_id = 456
      name = "concept_name"
      description = "concept_description"
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
          "description" => description,
          "template" => %{"name" => template},
          "domain" => %{"name" => domain},
          "content" => %{field_name => field_value},
          "status" => status,
          "inserted_at" => inserted_at,
          "last_change_at" => last_change_at
        }
      ]

      header_labels = %{
        "template" => "Plantilla",
        "description" => "Descripción",
        "link_to_concept" => "Enlace a concepto",
        "last_change_at" => "Fecha de última modificación"
      }

      csv = Download.to_csv(concepts, header_labels, @concept_url_schema)

      assert csv == """
             Plantilla;name;domain;status;Descripción;completeness;Enlace a concepto;inserted_at;Fecha de última modificación;#{field_label}\r
             #{template};#{name};#{domain};#{status};#{description};100.0;https://test.io/concepts/#{business_concept_id}/versions/#{business_concept_version_id};#{inserted_at};#{last_change_at};#{field_value}\r
             """
    end

    test "to_csv/1 return business concepts non-dynamic content when related template does not exist" do
      template = @template_name
      field_name = "field_name"

      name = "concept_name"
      description = "concept_description"
      domain = "domain_name"
      field_value = "field_value"
      status = "draft"
      inserted_at = "2018-05-05"
      last_change_at = "2018-05-06"

      concepts = [
        %{
          "name" => name,
          "description" => description,
          "template" => %{"name" => template},
          "domain" => %{"name" => domain},
          "content" => %{field_name => field_value},
          "status" => status,
          "inserted_at" => inserted_at,
          "last_change_at" => last_change_at
        }
      ]

      header_labels = %{
        "template" => "Plantilla",
        "description" => "Descripción",
        "last_change_at" => "Fecha de última modificación"
      }

      csv = Download.to_csv(concepts, header_labels)

      assert csv == """
             Plantilla;name;domain;status;Descripción;completeness;inserted_at;Fecha de última modificación\r
             #{template};#{name};#{domain};#{status};#{description};;#{inserted_at};#{last_change_at}\r
             """
    end

    test "to_csv/1 return business concepts non-dynamic content when related template does not exist with url" do
      template = @template_name
      field_name = "field_name"

      business_concept_id = 123
      business_concept_version_id = 456
      name = "concept_name"
      description = "concept_description"
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
          "description" => description,
          "template" => %{"name" => template},
          "domain" => %{"name" => domain},
          "content" => %{field_name => field_value},
          "status" => status,
          "inserted_at" => inserted_at,
          "last_change_at" => last_change_at
        }
      ]

      header_labels = %{
        "template" => "Plantilla",
        "description" => "Descripción",
        "link_to_concept" => "Enlace a concepto",
        "last_change_at" => "Fecha de última modificación"
      }

      csv = Download.to_csv(concepts, header_labels, @concept_url_schema)

      assert csv == """
             Plantilla;name;domain;status;Descripción;completeness;Enlace a concepto;inserted_at;Fecha de última modificación\r
             #{template};#{name};#{domain};#{status};#{description};;https://test.io/concepts/123/versions/456;#{inserted_at};#{last_change_at}\r
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
    test "to_csv/1 return formatted fields in concepts with dynamic content" do
      template = @template_name

      url_field = "url_field"
      url_label = "Url"

      key_value_field = "key_value"
      key_value_label = "Key And Value"

      name = "concept_name"
      description = "concept_description"
      domain = "domain_name"
      status = "draft"
      inserted_at = "2018-05-05"
      last_change_at = "2018-05-06"

      concepts = [
        %{
          "name" => name,
          "description" => description,
          "template" => %{"name" => template},
          "domain" => %{"name" => domain},
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

      header_labels = %{
        "template" => "Plantilla",
        "description" => "Descripción",
        "last_change_at" => "Fecha de última modificación"
      }

      csv = Download.to_csv(concepts, header_labels)
      [headers, content] = csv |> String.split("\r\n") |> Enum.filter(&(&1 != ""))

      assert headers ==
               "Plantilla;name;domain;status;Descripción;completeness;inserted_at;Fecha de última modificación;#{url_label};#{key_value_label}"

      assert content ==
               "#{template};#{name};#{domain};#{status};#{description};100.0;#{inserted_at};#{last_change_at};#{url_fields};#{key_value_fields}"
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
    test "to_csv/1 return formatted fields in concepts with dynamic content with link" do
      template = @template_name

      url_field = "url_field"
      url_label = "Url"

      key_value_field = "key_value"
      key_value_label = "Key And Value"

      business_concept_id = 123
      business_concept_version_id = 456
      name = "concept_name"
      description = "concept_description"
      domain = "domain_name"
      status = "draft"
      inserted_at = "2018-05-05"
      last_change_at = "2018-05-06"

      concepts = [
        %{
          "business_concept_id" => business_concept_id,
          "id" => business_concept_version_id,
          "name" => name,
          "description" => description,
          "template" => %{"name" => template},
          "domain" => %{"name" => domain},
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

      header_labels = %{
        "template" => "Plantilla",
        "description" => "Descripción",
        "link_to_concept" => "Enlace a concepto",
        "last_change_at" => "Fecha de última modificación"
      }

      csv = Download.to_csv(concepts, header_labels, @concept_url_schema)
      [headers, content] = csv |> String.split("\r\n") |> Enum.filter(&(&1 != ""))

      assert headers ==
               "Plantilla;name;domain;status;Descripción;completeness;Enlace a concepto;inserted_at;Fecha de última modificación;#{url_label};#{key_value_label}"

      assert content ==
               "#{template};#{name};#{domain};#{status};#{description};100.0;https://test.io/concepts/123/versions/456;#{inserted_at};#{last_change_at};#{url_fields};#{key_value_fields}"
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
    test "to_csv/1 return calculated completeness" do
      template = @template_name

      name = "concept_name"
      description = "concept_description"
      domain = "domain_name"
      status = "draft"
      inserted_at = "2018-05-05"
      last_change_at = "2018-05-06"

      concepts = [
        %{
          "name" => name,
          "description" => description,
          "template" => %{"name" => template},
          "domain" => %{"name" => domain},
          "content" => %{
            "field1" => "value",
            "field2" => "value"
          },
          "status" => status,
          "inserted_at" => inserted_at,
          "last_change_at" => last_change_at
        }
      ]

      header_labels = %{
        "template" => "Plantilla",
        "description" => "Descripción",
        "last_change_at" => "Fecha de última modificación"
      }

      csv = Download.to_csv(concepts, header_labels)
      [headers, content] = csv |> String.split("\r\n") |> Enum.filter(&(&1 != ""))

      assert headers ==
               "Plantilla;name;domain;status;Descripción;completeness;inserted_at;Fecha de última modificación;field1;field2;field3"

      assert content ==
               "#{template};#{name};#{domain};#{status};#{description};66.67;#{inserted_at};#{last_change_at};value;value;"
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
    test "to_csv/1 return calculated completeness with url" do
      template = @template_name

      business_concept_id = 123
      business_concept_version_id = 456
      name = "concept_name"
      description = "concept_description"
      domain = "domain_name"
      status = "draft"
      inserted_at = "2018-05-05"
      last_change_at = "2018-05-06"

      concepts = [
        %{
          "business_concept_id" => business_concept_id,
          "id" => business_concept_version_id,
          "name" => name,
          "description" => description,
          "template" => %{"name" => template},
          "domain" => %{"name" => domain},
          "content" => %{
            "field1" => "value",
            "field2" => "value"
          },
          "status" => status,
          "inserted_at" => inserted_at,
          "last_change_at" => last_change_at
        }
      ]

      header_labels = %{
        "template" => "Plantilla",
        "description" => "Descripción",
        "link_to_concept" => "Enlace a concepto",
        "last_change_at" => "Fecha de última modificación"
      }

      csv = Download.to_csv(concepts, header_labels, @concept_url_schema)
      [headers, content] = csv |> String.split("\r\n") |> Enum.filter(&(&1 != ""))

      assert headers ==
               "Plantilla;name;domain;status;Descripción;completeness;Enlace a concepto;inserted_at;Fecha de última modificación;field1;field2;field3"

      assert content ==
               "#{template};#{name};#{domain};#{status};#{description};66.67;https://test.io/concepts/123/versions/456;#{inserted_at};#{last_change_at};value;value;"
    end
  end
end
