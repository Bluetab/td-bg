defmodule TdBg.BusinessConceptDownloadTests do
  use TdBg.DataCase

  @template_name "download_template"

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
             Plantilla;name;domain;status;Descripción;inserted_at;Fecha de última modificación;#{field_label}\r
             #{template};#{name};#{domain};#{status};#{description};#{inserted_at};#{last_change_at};#{field_value}\r
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
             Plantilla;name;domain;status;Descripción;inserted_at;Fecha de última modificación\r
             #{template};#{name};#{domain};#{status};#{description};#{inserted_at};#{last_change_at}\r
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

      url_fields = "www.com.com, www.net.net"
      key_value_fields = "First Element, Second Element"

      header_labels = %{
        "template" => "Plantilla",
        "description" => "Descripción",
        "last_change_at" => "Fecha de última modificación"
      }

      csv = Download.to_csv(concepts, header_labels)
      [headers, content] = csv |> String.split("\r\n") |> Enum.filter(&(&1 != ""))

      assert headers ==
               "Plantilla;name;domain;status;Descripción;inserted_at;Fecha de última modificación;#{url_label};#{key_value_label}"

      assert content ==
               "#{template};#{name};#{domain};#{status};#{description};#{inserted_at};#{last_change_at};#{url_fields};#{key_value_fields}"
    end
  end
end
