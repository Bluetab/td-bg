defmodule TdBg.BusinessConceptDownloadTests do
  use TdBg.DataCase

  describe "business_concept_download" do
    alias TdBg.BusinessConcept.Download

    test "to_csv/1 return cvs content to download" do
      template_name = "template_name"
      field_name = "field_name"
      field_label = "field_label"
      insert(:template, name: template_name, content: [%{
          name: field_name,
          type: "list",
          label: field_label
        }
      ])

      concept_name = "concept_name"
      concept_description = "concept_description"
      domain_name = "domain_name"
      field_value = "field_value"
      concept_status = "draft"
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
        "status" => concept_status
      }]

      csv = Download.to_csv(concepts)
      assert csv == "template;name;domain;status;description;#{field_label}\r\n#{template_name};#{concept_name};#{domain_name};#{concept_status};#{concept_description};#{field_value}\r\n"
    end
  end
end
