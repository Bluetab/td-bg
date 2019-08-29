defmodule TdBg.BusinessConceptsTest do
  use TdBg.DataCase

  alias TdBg.BusinessConcepts
  alias TdBg.BusinessConcepts.BusinessConceptVersion
  alias TdCache.TemplateCache
  alias TdDfLib.RichText

  def create_template(template) do
    TemplateCache.put(template)
    template
  end

  describe "business_concepts" do
    defp fixture do
      template_content = [%{name: "fieldname", type: "string", cardinality: "?"}]

      template =
        create_template(%{
          id: 0,
          name: "onefield",
          content: template_content,
          label: "label",
          scope: "test"
        })

      parent_domain = insert(:domain)
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

  describe "business_concept diff" do
    defp diff_fixture do
      old = %BusinessConceptVersion{
        name: "name1",
        description: %{foo: "bar"},
        content: %{change: "will change", remove: "will remove", keep: "keep"}
      }

      new = %BusinessConceptVersion{
        name: "name2",
        description: %{bar: "foo"},
        content: %{change: "was changed", keep: "keep", add: "was added"}
      }

      {old, new}
    end

    test "diff/2 returns the difference between two business concept versions" do
      {old, new} = diff_fixture()

      %{name: name, description: description, content: content} = BusinessConcepts.diff(old, new)

      assert name == new.name
      assert description == new.description

      %{added: added, changed: changed, removed: removed} = content

      assert added == %{add: new.content.add}
      assert changed == %{change: new.content.change}
      assert removed == %{remove: old.content.remove}
    end
  end

  test "create_business_concept/1 with invalid content: required" do
    user = build(:user)
    domain = insert(:domain)

    content_schema = [
      %{
        "name" => "data_owner",
        "type" => "user",
        "group" => "New Group 1",
        "label" => "data_owner",
        "values" => %{"role_users" => "data_owner", "processed_users" => []},
        "widget" => "dropdown",
        "cardinality" => "1"
      },
      %{
        "name" => "texto_libre",
        "type" => "enriched_text",
        "group" => "New Group 1",
        "label" => "texto libre",
        "widget" => "enriched_text",
        "cardinality" => "1"
      },
      %{
        "name" => "link",
        "type" => "url",
        "group" => "New Group 1",
        "label" => "link",
        "widget" => "pair_list",
        "cardinality" => "+"
      },
      %{
        "name" => "lista",
        "type" => "string",
        "group" => "New Group 1",
        "label" => "lista",
        "values" => %{"fixed_tuple" => [%{"text" => "valor1", "value" => "codigo1"}]},
        "widget" => "dropdown",
        "cardinality" => "+"
      }
    ]

    content = %{
      "data_owner" => "domain",
      "link" => "https://google.es",
      "lista" => "valor1",
      "texto_libre" => "free text"
    }

    concept_attrs = %{
      type: "some_type",
      domain_id: domain.id,
      last_change_by: user.id,
      last_change_at: DateTime.utc_now()
    }

    version_attrs = %{
      business_concept: concept_attrs,
      content: content,
      related_to: [],
      name: "some name",
      description: RichText.to_rich_text("some description"),
      last_change_by: user.id,
      last_change_at: DateTime.utc_now(),
      version: 1
    }

    creation_attrs = Map.put(version_attrs, :content_schema, content_schema)

    assert {:ok, %BusinessConceptVersion{} = object} =
             BusinessConcepts.create_business_concept(creation_attrs)

    assert object.content == %{
             "data_owner" => "domain",
             "link" => [
               %{
                 "url_name" => "https://google.es",
                 "url_value" => "https://google.es"
               }
             ],
             "lista" => ["codigo1"],
             "texto_libre" => RichText.to_rich_text("free text")
           }

    assert object.name == version_attrs.name
    assert object.description == version_attrs.description
    assert object.last_change_by == version_attrs.last_change_by
    assert object.current == true
    assert object.in_progress == false
    assert object.version == version_attrs.version
    assert object.business_concept.type == concept_attrs.type
    assert object.business_concept.domain_id == concept_attrs.domain_id
    assert object.business_concept.last_change_by == concept_attrs.last_change_by
  end
end
