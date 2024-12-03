defmodule TdBg.BusinessConcepts.BusinessConceptVersionTest do
  use TdBg.DataCase

  alias Ecto.Changeset
  alias Elasticsearch.Document
  alias TdBg.BusinessConcepts.BusinessConceptVersion

  @unsafe "javascript:alert(document)"

  setup do
    identifier_name = "identifier"
    template_name = "template_with_identifier"

    with_identifier = %{
      id: System.unique_integer([:positive]),
      name: template_name,
      label: "concept_with_identifier",
      scope: "bg",
      content: [
        %{
          "fields" => [
            %{
              "cardinality" => "1",
              "default" => %{"value" => "", "origin" => "default"},
              "label" => "Identifier",
              "name" => identifier_name,
              "subscribable" => false,
              "type" => "string",
              "values" => nil,
              "widget" => "identifier"
            },
            %{
              "cardinality" => "1",
              "default" => %{"value" => "", "origin" => "default"},
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
    %{id: domain_id} = domain = CacheHelpers.insert_domain()

    create_attrs = %{
      content: %{"text" => %{"value" => "foo", "origin" => "user"}},
      content_schema: template_with_identifier.content,
      name: "some name",
      last_change_by: 1,
      last_change_at: DateTime.utc_now(),
      version: 1,
      business_concept: %{id: 1, type: template_with_identifier.name, domain_id: domain_id},
      in_progress: true
    }

    [
      template_with_identifier: template_with_identifier,
      identifier_name: identifier_name,
      create_attrs: create_attrs,
      domain: domain
    ]
  end

  describe "BusinessConceptVersion.create_changeset/2" do
    test "trims name", %{create_attrs: create_attrs} do
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
  end

  describe "BusinessConceptVersion.validate_content/1" do
    test "validates unsafe content and description", %{create_attrs: create_attrs} do
      create_attrs =
        Map.put(create_attrs, :content, %{
          "foo" => %{"value" => [@unsafe], "origin" => "user"},
          "text" => %{"value" => "bar", "origin" => "user"}
        })

      assert %{valid?: false, errors: errors} =
               %BusinessConceptVersion{}
               |> BusinessConceptVersion.create_changeset(create_attrs)
               |> BusinessConceptVersion.validate_content()

      assert errors[:content] == {"invalid content", []}
    end

    test "validates required content", %{create_attrs: create_attrs} do
      create_attrs =
        Map.put(create_attrs, :content, %{"identifier" => %{"value" => "foo", "origin" => "user"}})

      assert %{valid?: false, errors: errors} =
               %BusinessConceptVersion{}
               |> BusinessConceptVersion.create_changeset(create_attrs)
               |> BusinessConceptVersion.validate_content()

      assert {"text: can't be blank", _} = errors[:content]
    end
  end

  describe "BusinessConceptVersion.update_changeset/2" do
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
          content: %{
            identifier_name => %{"value" => existing_identifier, "origin" => "autogenerated"}
          }
        })

      assert %Changeset{changes: changes} =
               BusinessConceptVersion.update_changeset(business_concept_version, %{
                 content: %{"text" => %{"value" => "some update", "origin" => "user"}}
               })

      assert %{content: new_content} = changes

      assert %{
               ^identifier_name => %{"value" => ^existing_identifier, "origin" => "autogenerated"}
             } = new_content
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
          content: %{
            identifier_name => %{"value" => existing_identifier, "origin" => "autogenerated"}
          }
        })

      assert %Changeset{changes: changes} =
               BusinessConceptVersion.update_changeset(business_concept_version, %{
                 content: %{
                   "text" => %{"value" => "some update", "origin" => "user"},
                   identifier_name => %{
                     "value" => "11111111-1111-1111-1111-111111111111",
                     "origin" => "user"
                   }
                 }
               })

      assert %{content: new_content} = changes

      assert %{
               ^identifier_name => %{"value" => ^existing_identifier, "origin" => "autogenerated"}
             } = new_content
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
                 content: %{"text" => %{"value" => "some update", "origin" => "user"}}
               })

      assert %{content: new_content} = changes
      assert %{^identifier_name => _identifier} = new_content
    end

    test "trims name" do
      bcv = insert(:business_concept_version)
      attrs = %{name: "   foo   "}
      changeset = BusinessConceptVersion.update_changeset(bcv, attrs)
      assert changeset.valid?
      assert Changeset.get_change(changeset, :name) == "foo"
    end

    test "sets status to draft" do
      bcv = insert(:business_concept_version, status: "published")
      attrs = %{name: "foo"}
      changeset = BusinessConceptVersion.update_changeset(bcv, attrs)
      assert changeset.valid?
      assert Changeset.get_change(changeset, :status) == "draft"
    end
  end

  describe "BusinessConceptVersion.bulk_update_changeset/2" do
    test "trims name" do
      bcv = insert(:business_concept_version)
      attrs = %{name: "   foo   "}
      changeset = BusinessConceptVersion.bulk_update_changeset(bcv, attrs)
      assert changeset.valid?
      assert Changeset.get_change(changeset, :name) == "foo"
    end

    test "does not change status" do
      bcv = insert(:business_concept_version, status: "published")
      attrs = %{name: "foo"}
      changeset = BusinessConceptVersion.bulk_update_changeset(bcv, attrs)
      assert changeset.valid?
      refute Changeset.get_change(changeset, :status)
    end
  end

  describe "Elasticsearch.Document.encode/2" do
    setup do
      template =
        build(:template,
          scope: "bg",
          content: [
            build(:template_group,
              fields: [
                build(:template_field, name: "domain", type: "domain", cardinality: "?"),
                build(:template_field, name: "domains", type: "domain", cardinality: "*")
              ]
            )
          ]
        )

      [template: CacheHelpers.insert_template(template)]
    end

    test "encodes a BusinessConceptVersion for indexing", %{template: template} do
      content = %{
        "domain" => %{"value" => 1, "origin" => "user"},
        "domains" => %{"value" => [1, 2], "origin" => "user"}
      }

      bcv =
        insert(:business_concept_version, content: content, type: template.name)
        |> Repo.preload(business_concept: :shared_to)

      assert %{content: encoded_content} = Document.encode(bcv)

      assert encoded_content == %{"domain" => 1, "domains" => [1, 2]}
    end

    test "encodes the latest last_changes" do
      %{id: last_user_id, email: email} = CacheHelpers.insert_user()
      %{id: old_user_id} = CacheHelpers.insert_user()

      last_datetime = DateTime.utc_now()
      old_datetime = DateTime.add(last_datetime, -5, :day)

      bcv =
        insert(:business_concept_version,
          last_change_at: last_datetime,
          last_change_by: last_user_id,
          business_concept:
            build(:business_concept, last_change_at: old_datetime, last_change_by: old_user_id)
        )
        |> Repo.preload(business_concept: :shared_to)

      assert %{
               last_change_at: ^last_datetime,
               last_change_by: %{id: ^last_user_id, email: ^email}
             } = Document.encode(bcv)

      bcv =
        insert(:business_concept_version,
          last_change_at: old_datetime,
          last_change_by: old_user_id,
          business_concept:
            build(:business_concept, last_change_at: last_datetime, last_change_by: last_user_id)
        )
        |> Repo.preload(business_concept: :shared_to)

      assert %{
               last_change_at: ^last_datetime,
               last_change_by: %{id: ^last_user_id, email: ^email}
             } = Document.encode(bcv)
    end
  end
end
