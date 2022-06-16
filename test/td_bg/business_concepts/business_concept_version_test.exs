defmodule TdBg.BusinessConcepts.BusinessConceptVersionTest do
  use TdBg.DataCase

  alias Ecto.Changeset
  alias TdBg.BusinessConcepts.BusinessConceptVersion

  @unsafe "javascript:alert(document)"

  setup do
    identifier_name = "identifier"

    with_identifier = %{
      id: System.unique_integer([:positive]),
      name: "Concept template with identifier field",
      label: "concept_with_identifier",
      scope: "bg",
      content: [
        %{
          "fields" => [
            %{
              "cardinality" => "1",
              "default" => "",
              "label" => "Identifier",
              "name" => identifier_name,
              "subscribable" => false,
              "type" => "string",
              "values" => nil,
              "widget" => "identifier"
            },
            %{
              "cardinality" => "1",
              "default" => "",
              "label" => "Text",
              "name" => "text",
              "subscribable" => false,
              "type" => "string",
              "values" => nil,
              "widget" => "text"
            }
          ],
          "name" => ""
        }
      ]
    }

    template_with_identifier = CacheHelpers.insert_template(with_identifier)

    create_attrs = %{
      content: %{},
      content_schema: template_with_identifier.content,
      name: "some name",
      last_change_by: 1,
      last_change_at: DateTime.utc_now(),
      version: 1,
      business_concept: %{id: 1, type: template_with_identifier.name},
      in_progress: true
    }

    [
      template_with_identifier: template_with_identifier,
      identifier_name: identifier_name,
      create_attrs: create_attrs
    ]
  end

  describe "TdBg.BusinessConcepts.BusinessConceptVersion" do
    test "create_changeset/2 trims name", %{create_attrs: create_attrs} do
      attrs = Map.put(create_attrs, :name, "  foo  ")
      changeset = BusinessConceptVersion.create_changeset(%BusinessConceptVersion{}, attrs)
      assert changeset.valid?
      assert Changeset.get_change(changeset, :name) == "foo"
    end

    test "puts a new identifier if the template has an identifier field", %{
      identifier_name: identifier_name,
      create_attrs: create_attrs
    } do
      assert %Changeset{changes: changes} =
               BusinessConceptVersion.create_changeset(%BusinessConceptVersion{}, create_attrs)

      assert %{content: new_content} = changes
      assert %{^identifier_name => _identifier} = new_content
    end

    test "avoids putting new identifier if template lacks an identifier field", %{
      identifier_name: identifier_name,
      create_attrs: create_attrs
    } do
      assert %Changeset{changes: changes} =
               BusinessConceptVersion.create_changeset(%BusinessConceptVersion{}, create_attrs)

      assert %{content: new_content} = changes
      assert %{^identifier_name => _identifier} = new_content
    end

    test "keeps an already present identifier (i.e., editing)", %{
      template_with_identifier: template_with_identifier,
      identifier_name: identifier_name
    } do
      # Existing identifier previously put by the create changeset
      existing_identifier = "00000000-0000-0000-0000-000000000000"
      business_concept = build(:business_concept, %{type: template_with_identifier.name})

      business_concept_version =
        build(:business_concept_version, %{
          business_concept: business_concept,
          content: %{identifier_name => existing_identifier}
        })

      assert %Changeset{changes: changes} =
               BusinessConceptVersion.update_changeset(business_concept_version, %{
                 content: %{"text" => "some update"}
               })

      assert %{content: new_content} = changes
      assert %{^identifier_name => ^existing_identifier} = new_content
    end

    test "keeps an already present identifier (i.e., editing) if extraneous identifier attr is passed",
         %{
           template_with_identifier: template_with_identifier,
           identifier_name: identifier_name
         } do
      # Existing identifier previously put by the create changeset
      existing_identifier = "00000000-0000-0000-0000-000000000000"
      business_concept = build(:business_concept, %{type: template_with_identifier.name})

      business_concept_version =
        build(:business_concept_version, %{
          business_concept: business_concept,
          content: %{identifier_name => existing_identifier}
        })

      assert %Changeset{changes: changes} =
               BusinessConceptVersion.update_changeset(business_concept_version, %{
                 content: %{
                   "text" => "some update",
                   identifier_name => "11111111-1111-1111-1111-111111111111"
                 }
               })

      assert %{content: new_content} = changes
      assert %{^identifier_name => ^existing_identifier} = new_content
    end

    test "puts an identifier if there is not already one and the template has an identifier field",
         %{template_with_identifier: template_with_identifier, identifier_name: identifier_name} do
      # Concept version has no identifier but its template does
      # This happens if identifier is added to template after concept creation
      # Test an update to the concept version in this state.
      business_concept = build(:business_concept, %{type: template_with_identifier.name})

      %{content: content} =
        business_concept_version =
        build(:business_concept_version, %{business_concept: business_concept})

      # Just to make sure factory does not add identifier
      refute match?(%{^identifier_name => _identifier}, content)

      assert %Changeset{changes: changes} =
               BusinessConceptVersion.update_changeset(business_concept_version, %{
                 content: %{"text" => "some update"}
               })

      assert %{content: new_content} = changes
      assert %{^identifier_name => _identifier} = new_content
    end

    test "update_changeset/2 trims name" do
      bcv = insert(:business_concept_version)
      attrs = %{name: "   foo   "}
      changeset = BusinessConceptVersion.update_changeset(bcv, attrs)
      assert changeset.valid?
      assert Changeset.get_change(changeset, :name) == "foo"
    end

    test "update_changeset/2 sets status to draft" do
      bcv = insert(:business_concept_version, status: "published")
      attrs = %{name: "foo"}
      changeset = BusinessConceptVersion.update_changeset(bcv, attrs)
      assert changeset.valid?
      assert Changeset.get_change(changeset, :status) == "draft"
    end

    test "bulk_update_changeset/2 trims name" do
      bcv = insert(:business_concept_version)
      attrs = %{name: "   foo   "}
      changeset = BusinessConceptVersion.bulk_update_changeset(bcv, attrs)
      assert changeset.valid?
      assert Changeset.get_change(changeset, :name) == "foo"
    end

    test "bulk_update_changeset/2 does not change status" do
      bcv = insert(:business_concept_version, status: "published")
      attrs = %{name: "foo"}
      changeset = BusinessConceptVersion.bulk_update_changeset(bcv, attrs)
      assert changeset.valid?
      refute Changeset.get_change(changeset, :status)
    end

    test "create_changeset/2 validates unsafe content and description", %{create_attrs: params} do
      params =
        params
        |> Map.put(:content, %{"foo" => [@unsafe]})
        |> Map.put(:description, %{"doc" => %{"href" => @unsafe}})

      assert %{valid?: false, errors: errors} =
               BusinessConceptVersion.create_changeset(%BusinessConceptVersion{}, params)

      assert errors[:content] == {"invalid content", []}
      assert errors[:description] == {"invalid content", []}
    end

    test "update_changeset/2 validates unsafe content and description" do
      bcv = insert(:business_concept_version)
      params = %{"description" => %{"doc" => @unsafe}, "content" => %{"foo" => [@unsafe]}}

      assert %{valid?: false, errors: errors} =
               BusinessConceptVersion.update_changeset(bcv, params)

      assert errors[:content] == {"invalid content", []}
      assert errors[:description] == {"invalid content", []}
    end
  end
end
