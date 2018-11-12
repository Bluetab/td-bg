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
      template_name = "template_name"
      field_name = "field_name"
      field_label = "field_label"
      create_template(%{
          id: 0,
          name: template_name,
          label: "label",
          content: [%{
            "name" => field_name,
            "type" => "list",
            "label" => field_label
          }
      ]})

      concept_name = "concept_name"
      concept_description = "concept_description"
      domain_name = "domain_name"
      field_value = "field_value"
      concept_status = "draft"
      inserted_at = "2018-05-05"
      concepts =  [%{
        "name" => concept_name,
        "description" => concept_description,
        "template" => %{"name" => template_name},
        "domain" => %{
          "name" => domain_name
        },
        "content" => %{
          field_name => field_value
        },
        "status" => concept_status,
        "inserted_at"=> inserted_at
      }]

      csv = Download.to_csv(concepts)
      assert csv == "template;name;domain;status;description;inserted_at;#{field_label}\r\n#{template_name};#{concept_name};#{domain_name};#{concept_status};#{concept_description};#{inserted_at};#{field_value}\r\n"
    end
  end
end
