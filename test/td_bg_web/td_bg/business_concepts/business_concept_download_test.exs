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
  end
end
