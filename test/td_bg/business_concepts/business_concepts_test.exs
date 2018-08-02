defmodule TdBg.BusinessConceptsTest do
  use TdBg.DataCase
  alias TdBg.BusinessConcepts

  describe "business_concepts" do

    defp fixture do
      template_content = [%{"name" => "fieldname", "type" => "string", "required" =>  false}]
      template = insert(:template, name: "onefield", content: template_content)
      parent_domain = insert(:domain, templates: [template])
      child_domain = insert(:child_domain, parent: parent_domain)
      insert(:business_concept, type: template.name, domain: child_domain)
      insert(:business_concept, type: template.name, domain: parent_domain)
    end

    test "list_all_business_concepts/0 return all business_concetps" do
      fixture()
      assert length(BusinessConcepts.list_all_business_concepts()) == 2
    end

    test "load_business_concept/1 return the expected business_concetp" do
      business_concept = fixture()
      assert business_concept.id == BusinessConcepts.get_business_concept!(business_concept.id).id
    end
  end
end
