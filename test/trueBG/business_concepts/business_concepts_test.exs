defmodule TdBG.BusinessConceptsTests do
  use TdBG.DataCase

  alias TdBG.Repo
  alias TdBG.BusinessConcepts

  describe "business_concepts" do
    alias TdBG.BusinessConcepts.BusinessConcept
    alias TdBG.BusinessConcepts.BusinessConceptVersion

    test "get_current_version_by_business_concept_id!/1 returns the business_concept with given id" do
      user = build(:user)
      business_concept_version = insert(:business_concept_version, last_change_by:  user.id)
      object = BusinessConcepts.get_current_version_by_business_concept_id!(business_concept_version.business_concept.id)
      assert  object |> business_concept_version_preload() == business_concept_version
    end

    test "create_business_concept_version/1 with valid data creates a business_concept" do
      user = build(:user)
      data_domain = insert(:data_domain)

      concept_attrs = %{
        type: "some type",
        data_domain_id: data_domain.id,
        last_change_by: user.id,
        last_change_at: DateTime.utc_now()
      }

      version_attrs = %{
        business_concept: concept_attrs,
        content: %{},
        name: "some name",
        description: "some description",
        last_change_by: user.id,
        last_change_at: DateTime.utc_now(),
        version: 1
      }

      creation_attrs = Map.put(version_attrs, :content_schema, [])
      assert {:ok, %BusinessConceptVersion{} = object} = BusinessConcepts.create_business_concept_version(creation_attrs)
      assert object.content == version_attrs.content
      assert object.name == version_attrs.name
      assert object.description == version_attrs.description
      assert object.last_change_by == version_attrs.last_change_by
      assert object.version == version_attrs.version
      assert object.business_concept.type == concept_attrs.type
      assert object.business_concept.data_domain_id == concept_attrs.data_domain_id
      assert object.business_concept.last_change_by == concept_attrs.last_change_by

    end

    test "create_business_concept_version/1 with invalid data returns error changeset" do
      version_attrs = %{
        business_concept: nil,
        content: %{},
        name: nil,
        description: nil,
        last_change_by: nil,
        last_change_at: nil,
        version: nil
      }

      creation_attrs = Map.put(version_attrs, :content_schema, [])
      assert {:error, %Ecto.Changeset{}} = BusinessConcepts.create_business_concept_version(creation_attrs)
    end

    test "create_business_concept_version_version/1 with content" do
      user = build(:user)
      data_domain = insert(:data_domain)

      content_schema = [
        %{"name" => "Field1", "type" => "string"},
        %{"name" => "Field2", "type" => "list",
          "values" => ["Hello", "World"]},
        %{"name" => "Field3", "type" => "variable_list"},
      ]

      content = %{Field1: "Hello", Field2: "World", Field3: ["Hellow", "World"]}

      concept_attrs = %{
        type: "some type",
        data_domain_id: data_domain.id,
        last_change_by: user.id,
        last_change_at: DateTime.utc_now()
      }

      version_attrs = %{
        business_concept: concept_attrs,
        content: content,
        name: "some name",
        description: "some description",
        last_change_by: user.id,
        last_change_at: DateTime.utc_now(),
        version: 1
      }

      creation_attrs = Map.put(version_attrs, :content_schema, content_schema)
      assert {:ok, %BusinessConceptVersion{} = object} = BusinessConcepts.create_business_concept_version(creation_attrs)
      assert object.content == content
    end

    test "create_business_concept_version_version/1 with invalid content: required" do
      user = build(:user)
      data_domain = insert(:data_domain)

      content_schema = [
        %{"name" => "Field1", "type" => "string", "required" => true},
        %{"name" => "Field2", "type" => "string", "required" => true}
      ]

      content = %{}

      concept_attrs = %{
        type: "some type",
        data_domain_id: data_domain.id,
        last_change_by: user.id,
        last_change_at: DateTime.utc_now()
      }

      version_attrs = %{
        business_concept: concept_attrs,
        content: content,
        name: "some name",
        description: "some description",
        last_change_by: user.id,
        last_change_at: DateTime.utc_now(),
        version: 1
      }

      creation_attrs = Map.put(version_attrs, :content_schema, content_schema)
      assert {:error, %Ecto.Changeset{} = changeset} = BusinessConcepts.create_business_concept_version(creation_attrs)
      changeset
      |> assert_expected_validation("Field1", :required)
      |> assert_expected_validation("Field2", :required)
    end

    test "create_business_concept_version_version/1 with content: default values" do
      user = build(:user)
      data_domain = insert(:data_domain)

      content_schema = [
        %{"name" => "Field1", "type" => "string", "default" => "Hello"},
        %{"name" => "Field2", "type" => "string", "default" => "World"}
      ]

      content = %{}

      concept_attrs = %{
        type: "some type",
        data_domain_id: data_domain.id,
        last_change_by: user.id,
        last_change_at: DateTime.utc_now()
      }

      version_attrs = %{
        business_concept: concept_attrs,
        content: content,
        name: "some name",
        description: "some description",
        last_change_by: user.id,
        last_change_at: DateTime.utc_now(),
        version: 1
      }

      creation_attrs = Map.put(version_attrs, :content_schema, content_schema)
      assert {:ok, %BusinessConceptVersion{} = business_concept_version} = BusinessConcepts.create_business_concept_version(creation_attrs)
      assert business_concept_version.content["Field1"] == "Hello"
      assert business_concept_version.content["Field2"] == "World"
    end

    test "create_business_concept_version_version/1 with invalid content: not in list" do
      user = build(:user)
      data_domain = insert(:data_domain)

      content_schema = [
        %{"name" => "Field1", "type" => "list", "values" => ["Hello"]},
      ]

      content = %{"Field1" => "World"}

      concept_attrs = %{
        type: "some type",
        data_domain_id: data_domain.id,
        last_change_by: user.id,
        last_change_at: DateTime.utc_now()
      }

      version_attrs = %{
        business_concept: concept_attrs,
        content: content,
        name: "some name",
        description: "some description",
        last_change_by: user.id,
        last_change_at: DateTime.utc_now(),
        version: 1
      }

      creation_attrs = Map.put(version_attrs, :content_schema, content_schema)
      assert {:error, %Ecto.Changeset{} = changeset} = BusinessConcepts.create_business_concept_version(creation_attrs)
      assert_expected_validation(changeset, "Field1", :inclusion)
    end

    test "create_business_concept_version_version/1 with invalid content: invalid variable list" do
      user = build(:user)
      data_domain = insert(:data_domain)

      content_schema = [
        %{"name" => "Field1", "type" => "variable_list"},
      ]

      content = %{"Field1" => "World"}

      concept_attrs = %{
        type: "some type",
        data_domain_id: data_domain.id,
        last_change_by: user.id,
        last_change_at: DateTime.utc_now()
      }

      version_attrs = %{
        business_concept: concept_attrs,
        content: content,
        name: "some name",
        description: "some description",
        last_change_by: user.id,
        last_change_at: DateTime.utc_now(),
        version: 1
      }

      creation_attrs = Map.put(version_attrs, :content_schema, content_schema)
      assert {:error, %Ecto.Changeset{} = changeset} = BusinessConcepts.create_business_concept_version(creation_attrs)
      assert_expected_validation(changeset, "Field1", :cast)
    end

    test "create_business_concept_version_version/1 with no content" do
      user = build(:user)
      data_domain = insert(:data_domain)

      content_schema = [
        %{"name" => "Field1", "type" => "variable_list"},
      ]

      concept_attrs = %{
        type: "some type",
        data_domain_id: data_domain.id,
        last_change_by: user.id,
        last_change_at: DateTime.utc_now()
      }

      version_attrs = %{
        business_concept: concept_attrs,
        name: "some name",
        description: "some description",
        last_change_by: user.id,
        last_change_at: DateTime.utc_now(),
        version: 1
      }

      creation_attrs = Map.put(version_attrs, :content_schema, content_schema)
      assert {:error, %Ecto.Changeset{} = changeset} = BusinessConcepts.create_business_concept_version(creation_attrs)
      assert_expected_validation(changeset, "content", :required)
    end

    test "create_business_concept_version_version/1 with nil content" do
      user = build(:user)
      data_domain = insert(:data_domain)

      content_schema = [
        %{"name" => "Field1", "type" => "variable_list"},
      ]

      concept_attrs = %{
        type: "some type",
        data_domain_id: data_domain.id,
        last_change_by: user.id,
        last_change_at: DateTime.utc_now()
      }

      version_attrs = %{
        business_concept: concept_attrs,
        content: nil,
        name: "some name",
        description: "some description",
        last_change_by: user.id,
        last_change_at: DateTime.utc_now(),
        version: 1
      }

      creation_attrs = Map.put(version_attrs, :content_schema, content_schema)
      assert {:error, %Ecto.Changeset{} = changeset} = BusinessConcepts.create_business_concept_version(creation_attrs)
      assert_expected_validation(changeset, "content", :required)
    end

    test "create_business_concept_version_version/1 with no content schema" do
      user = build(:user)
      data_domain = insert(:data_domain)

      concept_attrs = %{
        type: "some type",
        data_domain_id: data_domain.id,
        last_change_by: user.id,
        last_change_at: DateTime.utc_now()
      }

      creation_attrs = %{
        business_concept: concept_attrs,
        content: %{},
        name: "some name",
        description: "some description",
        last_change_by: user.id,
        last_change_at: DateTime.utc_now(),
        version: 1
      }

      assert_raise RuntimeError, "Content Schema is not defined for Business Concept", fn ->
        BusinessConcepts.create_business_concept_version(creation_attrs)
      end
    end

    test "exist_business_concept_by_type_and_name?/1 invalid type/name" do
      user = build(:user)
      business_concept_version = insert(:business_concept_version, last_change_by:  user.id)
      type = business_concept_version.business_concept.type
      name = business_concept_version.name
      assert {:ok, 1} == BusinessConcepts.exist_business_concept_by_type_and_name?(type, name, nil)
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
        name: "updated name",
        description: "updated description",
        last_change_by: user.id,
        last_change_at: DateTime.utc_now(),
        version: 1
      }

      update_attrs = Map.put(version_attrs, :content_schema, [])
      assert {:ok, %BusinessConceptVersion{} = object} = BusinessConcepts.update_business_concept_version(business_concept_version, update_attrs)

      assert object.name == version_attrs.name
      assert object.description == version_attrs.description
      assert object.last_change_by == version_attrs.last_change_by
      assert object.version == version_attrs.version

      assert object.business_concept.id == business_concept_version.business_concept.id
      assert object.business_concept.last_change_by == 1000

    end

    test "update_business_concept_version/2 with valid content data updates the business_concept" do
      content_schema = [
        %{"name" => "Field1", "type" => "string", "required"=> true},
        %{"name" => "Field2", "type" => "string", "required"=> true},
      ]

      user = build(:user)
      content = %{
        "Field1" => "First field",
        "Field2" => "Second field",
      }

      business_concept_version = insert(:business_concept_version, last_change_by:  user.id, content: content)

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
        name: "updated name",
        description: "updated description",
        last_change_by: user.id,
        last_change_at: DateTime.utc_now(),
        version: 1
      }

      update_attrs = Map.put(version_attrs, :content_schema, content_schema)
      assert {:ok, business_concept_version} = BusinessConcepts.update_business_concept_version(business_concept_version, update_attrs)
      assert %BusinessConceptVersion{} = business_concept_version
      assert business_concept_version.content["Field1"] == "New first field"
      assert business_concept_version.content["Field2"] == "Second field"
    end

    test "update_business_concept_version/2 with invalid data returns error changeset" do
      business_concept_version = insert(:business_concept_version)

      version_attrs = %{
        business_concept: nil,
        content: %{},
        name: nil,
        description: nil,
        last_change_by: nil,
        last_change_at: nil,
        version: nil
      }

      update_attrs = Map.put(version_attrs, :content_schema, [])
      assert {:error, %Ecto.Changeset{}} = BusinessConcepts.update_business_concept_version(business_concept_version, update_attrs)
      object = BusinessConcepts.get_current_version_by_business_concept_id!(business_concept_version.business_concept.id)
      assert  object |> business_concept_version_preload() == business_concept_version
    end

    test "change_business_concept/1 returns a business_concept changeset" do
      user = build(:user)
      business_concept = insert(:business_concept, last_change_by:  user.id)
      assert %Ecto.Changeset{} = BusinessConcepts.change_business_concept(business_concept)
    end
  end

  describe "business_concept_versions" do
    alias TdBG.BusinessConcepts.BusinessConcept
    alias TdBG.BusinessConcepts.BusinessConceptVersion

    test "list_business_concept_versions/0 returns all business_concept_versions" do
      business_concept_version = insert(:business_concept_version)
      business_concept_versions = BusinessConcepts.list_business_concept_versions()
      assert  business_concept_versions |> Enum.map(fn(b) -> business_concept_version_preload(b) end)
            == [business_concept_version]

    end

    test "get_business_concept_version!/1 returns the business_concept_version with given id" do
      business_concept_version = insert(:business_concept_version)
      object = BusinessConcepts.get_business_concept_version!(business_concept_version.id)
      assert  object |> business_concept_version_preload() == business_concept_version
    end

    test "update_business_concept_version_status/2 with valid status data updates the business_concept" do
      user = build(:user)
      business_concept_version = insert(:business_concept_version, last_change_by:  user.id)
      attrs = %{status: BusinessConcept.status.published}
      assert {:ok, business_concept_version} = BusinessConcepts.update_business_concept_version_status(business_concept_version, attrs)
      assert business_concept_version.status == BusinessConcept.status.published
    end

    test "reject_business_concept_version/2 rejects business_concept" do
      user = build(:user)
      business_concept_version = insert(:business_concept_version,
                                status: BusinessConcept.status.pending_approval,
                                last_change_by:  user.id)
      attrs = %{reject_reason: "Because I want to"}
      assert {:ok, business_concept_version} = BusinessConcepts.reject_business_concept_version(business_concept_version, attrs)
      assert business_concept_version.status == BusinessConcept.status.rejected
      assert business_concept_version.reject_reason == attrs.reject_reason
    end

    test "change_business_concept_version/1 returns a business_concept_version changeset" do
      user = build(:user)
      business_concept_version = insert(:business_concept_version, last_change_by:  user.id)
      assert %Ecto.Changeset{} = BusinessConcepts.change_business_concept_version(business_concept_version)
    end
  end

  defp business_concept_version_preload(business_concept_version) do
    business_concept_version
      |> Repo.preload(:business_concept)
      |> Repo.preload(business_concept: [:data_domain])
      |> Repo.preload(business_concept: [data_domain: [:domain_group]])
  end

  defp assert_expected_validation(changeset, field, expected_validation) do
    find_def = {:unknown, {"", [validation: :unknown]}}
    current_validation = changeset.errors
    |> Enum.find(find_def, fn {key, _value} ->
       key == String.to_atom(field)
     end) |> elem(1) |> elem(1) |> Keyword.get(:validation)
    assert current_validation == expected_validation
    changeset
  end

end
