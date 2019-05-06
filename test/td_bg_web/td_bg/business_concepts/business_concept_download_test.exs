defmodule TdBg.BusinessConceptDownloadTests do
  use TdBg.DataCase

  @df_cache Application.get_env(:td_bg, :df_cache)

  setup_all do
    start_supervised(@df_cache)
    :ok
  end

  def create_template(template) do
    @df_cache.put_template(template)
    template
  end

  describe "business_concept_download" do
    alias TdBg.BusinessConcept.Download

    test "to_csv/1 return cvs content to download" do
      template = "template_name"
      field_name = "field_name"
      field_label = "field_label"

      create_template(%{
        id: 0,
        name: template,
        label: "label",
        content: [
          %{
            "name" => field_name,
            "type" => "list",
            "label" => field_label
          }
        ]
      })

      name = "concept_name"
      description = "concept_description"
      domain = "domain_name"
      field_value = "field_value"
      status = "draft"
      inserted_at = "2018-05-05"

      concepts = [
        %{
          "name" => name,
          "description" => description,
          "template" => %{"name" => template},
          "domain" => %{"name" => domain},
          "content" => %{field_name => field_value},
          "status" => status,
          "inserted_at" => inserted_at
        }
      ]

      header_labels = %{"template" => "Plantilla", "description" => "Descripción"}
      csv = Download.to_csv(concepts, header_labels)

      assert csv == """
             Plantilla;name;domain;status;Descripción;inserted_at;#{field_label}\r
             #{template};#{name};#{domain};#{status};#{description};#{inserted_at};#{field_value}\r
             """
    end

    test "to_csv/1 return business concepts non-dynamic content when related template does not exist" do
      template = "template_name_delete"
      field_name = "field_name"

      name = "concept_name"
      description = "concept_description"
      domain = "domain_name"
      field_value = "field_value"
      status = "draft"
      inserted_at = "2018-05-05"

      concepts = [
        %{
          "name" => name,
          "description" => description,
          "template" => %{"name" => template},
          "domain" => %{"name" => domain},
          "content" => %{field_name => field_value},
          "status" => status,
          "inserted_at" => inserted_at
        }
      ]

      header_labels = %{"template" => "Plantilla", "description" => "Descripción"}
      csv = Download.to_csv(concepts, header_labels)

      assert csv == """
             Plantilla;name;domain;status;Descripción;inserted_at\r
             #{template};#{name};#{domain};#{status};#{description};#{inserted_at}\r
             """
    end

    test "to_csv/1 return formatted fields in concepts with dynamic content" do
      template = "template_formatted_fields"

      url_field = "url_field"
      url_label = "Url"

      key_value_field = "key_value"
      key_value_label = "Key And Value"

      create_template(%{
        id: 0,
        name: template,
        label: "label",
        content: [
          %{
            "name" => url_field,
            "type" => "url",
            "label" => url_label
          },
          %{
            "name" => key_value_field,
            "type" => "string",
            "label" => key_value_label,
            "values" => %{
              "fixed_tuple" => [
                %{"text" => "First Element", "value" => "1"},
                %{"text" => "Second Element", "value" => "2"}
              ]
            }
          }
        ]
      })

      name = "concept_name"
      description = "concept_description"
      domain = "domain_name"
      status = "draft"
      inserted_at = "2018-05-05"

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
          "inserted_at" => inserted_at
        }
      ]

      url_fields = "www.com.com, www.net.net"
      key_value_fields = "First Element, Second Element"

      header_labels = %{"template" => "Plantilla", "description" => "Descripción"}
      csv = Download.to_csv(concepts, header_labels)
      [headers, content] = csv |> String.split("\r\n") |> Enum.filter(&(&1 != ""))

      assert headers ==
               "Plantilla;name;domain;status;Descripción;inserted_at;#{url_label};#{
                 key_value_label
               }"

      assert content ==
               "#{template};#{name};#{domain};#{status};#{description};#{inserted_at};#{
                 url_fields
               };#{key_value_fields}"
    end
  end
end
