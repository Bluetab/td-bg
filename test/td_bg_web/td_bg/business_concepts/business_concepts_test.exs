defmodule TdBg.BusinessConceptsTests do
  use TdBg.DataCase

  alias TdBg.Accounts.User
  alias TdBg.BusinessConcepts
  alias TdBg.Repo
  alias TdBgWeb.ApiServices.MockTdAuthService

  setup_all do
    start_supervised(MockTdAuthService)
    :ok
  end

  defp to_rich_text(plain) do
    %{"document" => plain}
  end

  describe "business_concepts" do
    alias TdBg.BusinessConcepts.BusinessConcept
    alias TdBg.BusinessConcepts.BusinessConceptAlias
    alias TdBg.BusinessConcepts.BusinessConceptVersion

    test "get_current_version_by_business_concept_id!/1 returns the business_concept with given id" do
      user = build(:user)
      business_concept_version = insert(:business_concept_version, last_change_by: user.id)

      object =
        BusinessConcepts.get_current_version_by_business_concept_id!(
          business_concept_version.business_concept.id
        )

      assert object |> business_concept_version_preload() == business_concept_version
    end

    test "get_current_version_by_business_concept_id!/1 returns the business concept with several aliases" do
      business_concept_version = insert(:business_concept_version)
      business_concept_id = business_concept_version.business_concept.id

      creation_attrs = %{business_concept_id: business_concept_id, name: "Alias 1"}

      assert {:ok, %BusinessConceptAlias{} = _bc} =
               BusinessConcepts.create_business_concept_alias(creation_attrs)

      creation_attrs = %{business_concept_id: business_concept_id, name: "Alias 2"}

      assert {:ok, %BusinessConceptAlias{} = _bc} =
               BusinessConcepts.create_business_concept_alias(creation_attrs)

      business_concept_version =
        BusinessConcepts.get_current_version_by_business_concept_id!(business_concept_id)

      assert length(business_concept_version.business_concept.aliases) == 2
    end

    test "create_business_concept/1 with valid data creates a business_concept" do
      user = build(:user)
      domain = insert(:domain)

      concept_attrs = %{
        type: "some_type",
        domain_id: domain.id,
        last_change_by: user.id,
        last_change_at: DateTime.utc_now()
      }

      version_attrs = %{
        business_concept: concept_attrs,
        content: %{},
        related_to: [],
        name: "some name",
        description: to_rich_text("some description"),
        last_change_by: user.id,
        last_change_at: DateTime.utc_now(),
        version: 1,
        in_progress: false
      }

      creation_attrs = Map.put(version_attrs, :content_schema, [])

      assert {:ok, %BusinessConceptVersion{} = object} =
               BusinessConcepts.create_business_concept(creation_attrs)

      assert object.content == version_attrs.content
      assert object.name == version_attrs.name
      assert object.description == version_attrs.description
      assert object.last_change_by == version_attrs.last_change_by
      assert object.current == true
      assert object.version == version_attrs.version
      assert object.business_concept.type == concept_attrs.type
      assert object.business_concept.domain_id == concept_attrs.domain_id
      assert object.business_concept.last_change_by == concept_attrs.last_change_by
    end

    test "create_business_concept/1 with invalid data returns error changeset" do
      version_attrs = %{
        business_concept: nil,
        content: %{},
        related_to: [],
        name: nil,
        description: nil,
        last_change_by: nil,
        last_change_at: nil,
        version: nil,
        in_progress: nil
      }

      creation_attrs = Map.put(version_attrs, :content_schema, [])

      assert {:error, %Ecto.Changeset{}} =
               BusinessConcepts.create_business_concept(creation_attrs)
    end

    test "create_business_concept/1 with content" do
      user = build(:user)
      domain = insert(:domain)

      content_schema = [
        %{"name" => "Field1", "type" => "string"},
        %{"name" => "Field2", "type" => "list", "values" => ["Hello", "World"]},
        %{"name" => "Field3", "type" => "variable_list"}
      ]

      content = %{"Field1" => "Hello", "Field2" => "World", "Field3" => ["Hellow", "World"]}

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
        description: to_rich_text("some description"),
        last_change_by: user.id,
        last_change_at: DateTime.utc_now(),
        version: 1,
        in_progress: false
      }

      creation_attrs = Map.put(version_attrs, :content_schema, content_schema)

      assert {:ok, %BusinessConceptVersion{} = object} =
               BusinessConcepts.create_business_concept(creation_attrs)

      assert object.content == content
    end

    test "create_business_concept/1 with invalid content: required" do
      user = build(:user)
      domain = insert(:domain)

      content_schema = [
        %{"name" => "Field1", "type" => "string", "required" => true},
        %{"name" => "Field2", "type" => "string", "required" => true}
      ]

      content = %{}

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
        description: to_rich_text("some description"),
        last_change_by: user.id,
        last_change_at: DateTime.utc_now(),
        version: 1,
        in_progress: false
      }

      creation_attrs = Map.put(version_attrs, :content_schema, content_schema)

      assert {:error, %Ecto.Changeset{} = changeset} =
               BusinessConcepts.create_business_concept(creation_attrs)

      changeset
      |> assert_expected_validation("Field1", :required)
      |> assert_expected_validation("Field2", :required)
    end

    test "create_business_concept/1 with content: default values" do
      user = build(:user)
      domain = insert(:domain)

      content_schema = [
        %{"name" => "Field1", "type" => "string", "default" => "Hello"},
        %{"name" => "Field2", "type" => "string", "default" => "World"}
      ]

      content = %{}

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
        description: to_rich_text("some description"),
        last_change_by: user.id,
        last_change_at: DateTime.utc_now(),
        version: 1,
        in_progress: false
      }

      creation_attrs = Map.put(version_attrs, :content_schema, content_schema)

      assert {:ok, %BusinessConceptVersion{} = business_concept_version} =
               BusinessConcepts.create_business_concept(creation_attrs)

      assert business_concept_version.content["Field1"] == "Hello"
      assert business_concept_version.content["Field2"] == "World"
    end

    test "create_business_concept/1 with invalid content: not in list" do
      user = build(:user)
      domain = insert(:domain)

      content_schema = [
        %{"name" => "Field1", "type" => "list", "values" => ["Hello"]}
      ]

      content = %{"Field1" => "World"}

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
        description: to_rich_text("some description"),
        last_change_by: user.id,
        last_change_at: DateTime.utc_now(),
        version: 1,
        in_progress: false
      }

      creation_attrs = Map.put(version_attrs, :content_schema, content_schema)

      assert {:error, %Ecto.Changeset{} = changeset} =
               BusinessConcepts.create_business_concept(creation_attrs)

      assert_expected_validation(changeset, "Field1", :inclusion)
    end

    test "create_business_concept/1 with invalid content: invalid variable list" do
      user = build(:user)
      domain = insert(:domain)

      content_schema = [
        %{"name" => "Field1", "type" => "variable_list"}
      ]

      content = %{"Field1" => "World"}

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
        description: to_rich_text("some description"),
        last_change_by: user.id,
        last_change_at: DateTime.utc_now(),
        version: 1,
        in_progress: false
      }

      creation_attrs = Map.put(version_attrs, :content_schema, content_schema)

      assert {:error, %Ecto.Changeset{} = changeset} =
               BusinessConcepts.create_business_concept(creation_attrs)

      assert_expected_validation(changeset, "Field1", :cast)
    end

    test "create_business_concept/1 with no content" do
      user = build(:user)
      domain = insert(:domain)

      content_schema = [
        %{"name" => "Field1", "type" => "variable_list"}
      ]

      concept_attrs = %{
        type: "some_type",
        domain_id: domain.id,
        last_change_by: user.id,
        last_change_at: DateTime.utc_now()
      }

      version_attrs = %{
        business_concept: concept_attrs,
        name: "some name",
        description: to_rich_text("some description"),
        last_change_by: user.id,
        last_change_at: DateTime.utc_now(),
        version: 1
      }

      creation_attrs = Map.put(version_attrs, :content_schema, content_schema)

      assert {:error, %Ecto.Changeset{} = changeset} =
               BusinessConcepts.create_business_concept(creation_attrs)

      assert_expected_validation(changeset, "content", :required)
    end

    test "create_business_concept/1 with nil content" do
      user = build(:user)
      domain = insert(:domain)

      content_schema = [
        %{"name" => "Field1", "type" => "variable_list"}
      ]

      concept_attrs = %{
        type: "some_type",
        domain_id: domain.id,
        last_change_by: user.id,
        last_change_at: DateTime.utc_now()
      }

      version_attrs = %{
        business_concept: concept_attrs,
        content: nil,
        related_to: [],
        name: "some name",
        description: to_rich_text("some description"),
        last_change_by: user.id,
        last_change_at: DateTime.utc_now(),
        version: 1,
        in_progress: false
      }

      creation_attrs = Map.put(version_attrs, :content_schema, content_schema)

      assert {:error, %Ecto.Changeset{} = changeset} =
               BusinessConcepts.create_business_concept(creation_attrs)

      assert_expected_validation(changeset, "content", :required)
    end

    test "create_business_concept/1 with no content schema" do
      user = build(:user)
      domain = insert(:domain)

      concept_attrs = %{
        type: "some_type",
        domain_id: domain.id,
        last_change_by: user.id,
        last_change_at: DateTime.utc_now()
      }

      creation_attrs = %{
        business_concept: concept_attrs,
        content: %{},
        related_to: [],
        name: "some name",
        description: to_rich_text("some description"),
        last_change_by: user.id,
        last_change_at: DateTime.utc_now(),
        version: 1,
        in_progress: false
      }

      assert_raise RuntimeError, "Content Schema is not defined for Business Concept", fn ->
        BusinessConcepts.create_business_concept(creation_attrs)
      end
    end

    test "check_business_concept_name_availability/2 check not available" do
      user = build(:user)
      business_concept_version = insert(:business_concept_version, last_change_by: user.id)
      type = business_concept_version.business_concept.type
      name = business_concept_version.name

      assert {:name_not_available} ==
               BusinessConcepts.check_business_concept_name_availability(type, name)
    end

    test "check_business_concept_name_availability/2 check available" do
      user = build(:user)
      business_concept_version = insert(:business_concept_version, last_change_by: user.id)
      exclude_concept_id = business_concept_version.business_concept.id
      type = business_concept_version.business_concept.type
      name = business_concept_version.name

      assert {:name_available} ==
               BusinessConcepts.check_business_concept_name_availability(
                 type,
                 name,
                 exclude_concept_id
               )
    end

    test "check_business_concept_name_availability/3 check not available" do
      user = build(:user)
      domain = insert(:domain)
      bc1 = insert(:business_concept, domain: domain)
      bc2 = insert(:business_concept, domain: domain)

      _first =
        insert(
          :business_concept_version,
          last_change_by: user.id,
          name: "first",
          business_concept: bc1
        )

      second =
        insert(
          :business_concept_version,
          last_change_by: user.id,
          name: "second",
          business_concept: bc2
        )

      assert {:name_not_available} ==
               BusinessConcepts.check_business_concept_name_availability(
                 second.business_concept.type,
                 "first",
                 second.id
               )
    end

    test "count_published_business_concepts/2 check count" do
      user = build(:user)

      business_concept_version =
        insert(
          :business_concept_version,
          last_change_by: user.id,
          status: BusinessConcept.status().published
        )

      type = business_concept_version.business_concept.type
      ids = [business_concept_version.business_concept.id]
      assert 1 == BusinessConcepts.count_published_business_concepts(type, ids)
    end

    test "update_business_concept_version/2 with valid data updates the business_concept_version" do
      user = build(:user)
      business_concept_version = insert(:business_concept_version)

      concept_attrs = %{
        last_change_by: 1000,
        last_change_at: DateTime.utc_now()
      }

      version_attrs = %{
        business_concept: concept_attrs,
        business_concept_id: business_concept_version.business_concept.id,
        content: %{},
        related_to: [],
        name: "updated name",
        description: to_rich_text("updated description"),
        last_change_by: user.id,
        last_change_at: DateTime.utc_now(),
        version: 1,
        in_progress: false
      }

      update_attrs = Map.put(version_attrs, :content_schema, [])

      assert {:ok, %BusinessConceptVersion{} = object} =
               BusinessConcepts.update_business_concept_version(
                 business_concept_version,
                 update_attrs
               )

      assert object.name == version_attrs.name
      assert object.description == version_attrs.description
      assert object.last_change_by == version_attrs.last_change_by
      assert object.current == true
      assert object.version == version_attrs.version

      assert object.business_concept.id == business_concept_version.business_concept.id
      assert object.business_concept.last_change_by == 1000
    end

    test "update_business_concept_version/2 with valid content data updates the business_concept" do
      content_schema = [
        %{"name" => "Field1", "type" => "string", "required" => true},
        %{"name" => "Field2", "type" => "string", "required" => true}
      ]

      user = build(:user)

      content = %{
        "Field1" => "First field",
        "Field2" => "Second field"
      }

      business_concept_version =
        insert(:business_concept_version, last_change_by: user.id, content: content)

      update_content = %{
        "Field1" => "New first field"
      }

      concept_attrs = %{
        last_change_by: 1000,
        last_change_at: DateTime.utc_now()
      }

      version_attrs = %{
        business_concept: concept_attrs,
        business_concept_id: business_concept_version.business_concept.id,
        content: update_content,
        related_to: [],
        name: "updated name",
        description: to_rich_text("updated description"),
        last_change_by: user.id,
        last_change_at: DateTime.utc_now(),
        version: 1,
        in_progress: false
      }

      update_attrs = Map.put(version_attrs, :content_schema, content_schema)

      assert {:ok, business_concept_version} =
               BusinessConcepts.update_business_concept_version(
                 business_concept_version,
                 update_attrs
               )

      assert %BusinessConceptVersion{} = business_concept_version
      assert business_concept_version.content["Field1"] == "New first field"
      assert business_concept_version.content["Field2"] == "Second field"
    end

    test "update_business_concept_version/2 with invalid data returns error changeset" do
      business_concept_version = insert(:business_concept_version)

      version_attrs = %{
        business_concept: nil,
        content: %{},
        related_to: [],
        name: nil,
        description: nil,
        last_change_by: nil,
        last_change_at: nil,
        version: nil,
        in_progress: nil
      }

      update_attrs = Map.put(version_attrs, :content_schema, [])

      assert {:error, %Ecto.Changeset{}} =
               BusinessConcepts.update_business_concept_version(
                 business_concept_version,
                 update_attrs
               )

      object =
        BusinessConcepts.get_current_version_by_business_concept_id!(
          business_concept_version.business_concept.id
        )

      assert object |> business_concept_version_preload() == business_concept_version
    end

    test "version_business_concept/2 creates a new version" do
      user = build(:user)

      business_concept_version =
        insert(
          :business_concept_version,
          last_change_by: user.id,
          status: BusinessConcept.status().published
        )

      assert {:ok, %{current: new_version}} =
               BusinessConcepts.version_business_concept(%User{id: 1234}, business_concept_version)

      assert %BusinessConceptVersion{} = new_version

      assert BusinessConcepts.get_business_concept_version!(business_concept_version.id).current ==
               false

      assert BusinessConcepts.get_business_concept_version!(new_version.id).current == true
    end

    test "change_business_concept/1 returns a business_concept changeset" do
      user = build(:user)
      business_concept = insert(:business_concept, last_change_by: user.id)
      assert %Ecto.Changeset{} = BusinessConcepts.change_business_concept(business_concept)
    end
  end

  describe "business_concept_versions" do
    alias TdBg.BusinessConcepts.BusinessConcept
    alias TdBg.BusinessConcepts.BusinessConceptVersion

    test "list_all_business_concept_versions/0 returns all business_concept_versions" do
      business_concept_version = insert(:business_concept_version)
      business_concept_versions = BusinessConcepts.list_all_business_concept_versions()

      assert business_concept_versions
             |> Enum.map(fn b -> business_concept_version_preload(b) end) ==
               [business_concept_version]
    end

    test "find_business_concept_versions/1 returns filtered business_concept_versions" do
      published = BusinessConcept.status().published
      draft = BusinessConcept.status().draft
      domain = insert(:domain)
      id = [create_version(domain, "one", draft).business_concept.id]
      id = [create_version(domain, "two", published).business_concept.id | id]
      id = [create_version(domain, "three", published).business_concept.id | id]

      business_concept_versions =
        BusinessConcepts.find_business_concept_versions(%{id: id, status: [published]})

      assert 2 == length(business_concept_versions)
    end

    defp create_version(domain, name, status) do
      business_concept = insert(:business_concept, domain: domain)

      insert(
        :business_concept_version,
        business_concept: business_concept,
        name: name,
        status: status
      )
    end

    test "list_business_concept_versions/1 returns all business_concept_versions of a business_concept_version" do
      business_concept_version = insert(:business_concept_version)
      business_concept_id = business_concept_version.business_concept.id

      business_concept_versions =
        BusinessConcepts.list_business_concept_versions(business_concept_id, [
          BusinessConcept.status().draft
        ])

      assert business_concept_versions
             |> Enum.map(fn b -> business_concept_version_preload(b) end) ==
               [business_concept_version]
    end

    test "get_business_concept_version!/1 returns the business_concept_version with given id" do
      business_concept_version = insert(:business_concept_version)
      object = BusinessConcepts.get_business_concept_version!(business_concept_version.id)
      assert object |> business_concept_version_preload() == business_concept_version
    end

    test "update_business_concept_version_status/2 with valid status data updates the business_concept" do
      user = build(:user)
      business_concept_version = insert(:business_concept_version, last_change_by: user.id)
      attrs = %{status: BusinessConcept.status().published}

      assert {:ok, business_concept_version} =
               BusinessConcepts.update_business_concept_version_status(
                 business_concept_version,
                 attrs
               )

      assert business_concept_version.status == BusinessConcept.status().published
    end

    test "reject_business_concept_version/2 rejects business_concept" do
      user = build(:user)

      business_concept_version =
        insert(
          :business_concept_version,
          status: BusinessConcept.status().pending_approval,
          last_change_by: user.id
        )

      attrs = %{reject_reason: "Because I want to"}

      assert {:ok, business_concept_version} =
               BusinessConcepts.reject_business_concept_version(business_concept_version, attrs)

      assert business_concept_version.status == BusinessConcept.status().rejected
      assert business_concept_version.reject_reason == attrs.reject_reason
    end

    test "change_business_concept_version/1 returns a business_concept_version changeset" do
      user = build(:user)
      business_concept_version = insert(:business_concept_version, last_change_by: user.id)

      assert %Ecto.Changeset{} =
               BusinessConcepts.change_business_concept_version(business_concept_version)
    end
  end

  defp business_concept_version_preload(business_concept_version) do
    business_concept_version
    |> Repo.preload(:business_concept)
    |> Repo.preload(business_concept: [:domain, :aliases])
    |> Repo.preload(business_concept: [domain: [:templates]])
  end

  defp assert_expected_validation(changeset, field, expected_validation) do
    find_def = {:unknown, {"", [validation: :unknown]}}

    current_validation =
      changeset.errors
      |> Enum.find(find_def, fn {key, _value} ->
        key == String.to_atom(field)
      end)
      |> elem(1)
      |> elem(1)
      |> Keyword.get(:validation)

    assert current_validation == expected_validation
    changeset
  end

  describe "business_concept_aliases" do
    alias TdBg.BusinessConcepts.BusinessConceptAlias

    defp create_business_concept_alias do
      business_concept_version = insert(:business_concept_version)

      insert(
        :business_concept_alias,
        business_concept_id: business_concept_version.business_concept.id
      )
    end

    test "list_business_concept_aliases/0 returns all business_concept_aliases" do
      business_concept_alias = create_business_concept_alias()

      assert BusinessConcepts.list_business_concept_aliases(
               business_concept_alias.business_concept_id
             ) == [business_concept_alias]
    end

    test "get_business_concept_alias!/1 returns the business_concept_alias with given id" do
      business_concept_alias = create_business_concept_alias()

      assert BusinessConcepts.get_business_concept_alias!(business_concept_alias.id) ==
               business_concept_alias
    end

    test "create_business_concept_alias/1 with valid data creates a business_concept_alias" do
      business_concept_version = insert(:business_concept_version)
      business_concept_id = business_concept_version.business_concept.id

      creation_attrs = %{
        business_concept_id: business_concept_id,
        name: "some name"
      }

      assert {:ok, %BusinessConceptAlias{} = business_concept_alias} =
               BusinessConcepts.create_business_concept_alias(creation_attrs)

      assert business_concept_alias.business_concept_id == business_concept_id
      assert business_concept_alias.name == "some name"
    end

    test "create_business_concept_alias/1 with invalid data returns error changeset" do
      business_concept_version = insert(:business_concept_version)
      business_concept_id = business_concept_version.business_concept.id

      creation_attrs = %{
        business_concept_id: business_concept_id,
        name: nil
      }

      assert {:error, %Ecto.Changeset{}} =
               BusinessConcepts.create_business_concept_alias(creation_attrs)
    end

    test "delete_business_concept_alias/1 deletes the business_concept_alias" do
      business_concept_alias = create_business_concept_alias()

      assert {:ok, %BusinessConceptAlias{}} =
               BusinessConcepts.delete_business_concept_alias(business_concept_alias)

      assert_raise Ecto.NoResultsError, fn ->
        BusinessConcepts.get_business_concept_alias!(business_concept_alias.id)
      end
    end

    test "change_business_concept_alias/1 returns a business_concept_alias changeset" do
      business_concept_alias = create_business_concept_alias()

      assert %Ecto.Changeset{} =
               BusinessConcepts.change_business_concept_alias(business_concept_alias)
    end
  end
end
