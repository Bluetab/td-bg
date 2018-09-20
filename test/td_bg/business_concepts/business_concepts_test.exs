defmodule TdBg.BusinessConceptsTest do
  use TdBg.DataCase
  alias TdBg.BusinessConcepts
  alias TdBg.Repo

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

  describe "business_concepts hierarchy" do

    defp create_hierarchy do
      domain = insert(:domain)
      parent = build(:business_concept, domain: domain)
      parent_version = insert(:business_concept_version, business_concept: parent)
      child  =  build(:business_concept, domain: domain, parent_id: parent_version.business_concept.id)
      child_version = insert(:business_concept_version, business_concept: child)

      {
        parent_version.business_concept.id,
        child_version.business_concept.id
      }
    end

    test "check parents" do
      {parent_id, child_id}  = create_hierarchy()

      parent = parent_id
      |> BusinessConcepts.get_current_version_by_business_concept_id!
      |> Map.get(:business_concept)

      child = child_id
      |> BusinessConcepts.get_current_version_by_business_concept_id!
      |> Map.get(:business_concept)
      |> Repo.preload(:parent)

      assert child.parent.id == parent.id
    end

    test "check children" do
      {parent_id, child_id}  = create_hierarchy()

      parent = parent_id
      |> BusinessConcepts.get_current_version_by_business_concept_id!
      |> Map.get(:business_concept)
      |> Repo.preload(:children)

      child = child_id
      |> BusinessConcepts.get_current_version_by_business_concept_id!
      |> Map.get(:business_concept)

      assert Enum.map(parent.children, &(&1.id)) == [child.id]
    end
  end
end
