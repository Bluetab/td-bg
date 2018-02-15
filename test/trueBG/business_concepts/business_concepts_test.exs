defmodule TrueBG.BusinessConceptsTests do
  use TrueBG.DataCase

  alias TrueBG.Repo
  alias TrueBG.BusinessConcepts
  alias Ecto.UUID

  describe "business_concepts" do
    alias TrueBG.BusinessConcepts.BusinessConcept

    defp business_concept_preload(business_concept) do
      business_concept
        |> Repo.preload(:data_domain)
        |> Repo.preload(data_domain: [:domain_group])
    end

    test "list_business_concepts/0 returns all business_concepts" do
      user = insert(:user)
      business_concept = insert(:business_concept, modifier: user.id)
      businnes_conceps = BusinessConcepts.list_business_concepts()
      assert  businnes_conceps |> Enum.map(fn(b) -> business_concept_preload(b) end)
            == [business_concept]
    end

    test "get_business_concept!/1 returns the business_concept with given id" do
      user = insert(:user)
      business_concept = insert(:business_concept, modifier:  user.id)
      object = BusinessConcepts.get_business_concept!(business_concept.id)
      assert  object |> business_concept_preload() == business_concept
    end

    test "create_business_concept/1 with valid data creates a business_concept" do
      user = insert(:user)
      data_domain = insert(:data_domain)

      attrs = %{type: "some type", name: "some name",
        description: "some description",  data_domain_id: data_domain.id,
        modifier: user.id, version_group_id: UUID.generate(),
        version: 1, content: %{},
        last_change: DateTime.utc_now()
      }

      creation_attrs = Map.put(attrs, :content_schema, [])
      assert {:ok, %BusinessConcept{} = business_concept} = BusinessConcepts.create_business_concept(creation_attrs)
      Enum.each(attrs, fn {attr, value} ->
        assert Map.get(business_concept, attr) == value
      end)
    end

    test "create_business_concept/1 with invalid data returns error changeset" do
      user = insert(:user)
      data_domain = insert(:data_domain)

      attrs = %{type: nil, name: nil,
        description: "some description",  data_domain_id: data_domain.id,
        modifier: user.id, version_group_id: UUID.generate(),
        version: 1, content: %{},
        last_change: DateTime.utc_now()
      }

      creation_attrs = Map.put(attrs, :content_schema, [])
      assert {:error, %Ecto.Changeset{}} = BusinessConcepts.create_business_concept(creation_attrs)
    end

    test "create_business_concept/1 with content" do
      user = insert(:user)
      data_domain = insert(:data_domain)

      content_schema = [
        %{"name" => "Field1", "type" => "string"},
        %{"name" => "Field2", "type" => "list",
          "values" => ["Hello", "World"]},
        %{"name" => "Field3", "type" => "variable_list"},
      ]

      content = %{Field1: "Hello", Field2: "World", Field3: ["Hellow", "World"]}

      attrs = %{type: "some type", name: "some name",
        description: "some description",  data_domain_id: data_domain.id,
        modifier: user.id, version_group_id: UUID.generate(),
        version: 1, content: content,
        last_change: DateTime.utc_now()
      }

      creation_attrs = Map.put(attrs, :content_schema, content_schema)
      assert {:ok, %BusinessConcept{} = business_concept} = BusinessConcepts.create_business_concept(creation_attrs)
      Enum.each(attrs, fn {attr, value} ->
        assert Map.get(business_concept, attr) == value
      end)
    end

    test "create_business_concept/1 with invalid content: required" do
      user = insert(:user)
      data_domain = insert(:data_domain)

      content_schema = [
        %{"name" => "Field1", "type" => "string", "required" => true},
        %{"name" => "Field2", "type" => "string", "required" => true}
      ]

      content = %{}

      attrs = %{type: "some type", name: "some name",
        description: "some description",  data_domain_id: data_domain.id,
        modifier: user.id, version_group_id: UUID.generate(),
        version: 1, content: content,
        last_change: DateTime.utc_now()
      }

      creation_attrs = Map.put(attrs, :content_schema, content_schema)
      assert {:error, %Ecto.Changeset{} = changeset} = BusinessConcepts.create_business_concept(creation_attrs)
      changeset
      |> assert_expected_validation("Field1", :required)
      |> assert_expected_validation("Field2", :required)
    end

    test "create_business_concept/1 with content: default values" do
      user = insert(:user)
      data_domain = insert(:data_domain)

      content_schema = [
        %{"name" => "Field1", "type" => "string", "default" => "Hello"},
        %{"name" => "Field2", "type" => "string", "default" => "World"}
      ]

      content = %{}

      attrs = %{type: "some type", name: "some name",
        description: "some description",  data_domain_id: data_domain.id,
        modifier: user.id, version_group_id: UUID.generate(),
        version: 1, content: content,
        last_change: DateTime.utc_now()
      }

      creation_attrs = Map.put(attrs, :content_schema, content_schema)
      assert {:ok, %BusinessConcept{} = business_concept} = BusinessConcepts.create_business_concept(creation_attrs)
      assert business_concept.content["Field1"] == "Hello"
      assert business_concept.content["Field2"] == "World"
    end

    test "create_business_concept/1 with invalid content: not in list" do
      user = insert(:user)
      data_domain = insert(:data_domain)

      content_schema = [
        %{"name" => "Field1", "type" => "list", "values" => ["Hello"]},
      ]

      content = %{"Field1" => "World"}

      attrs = %{type: "some type", name: "some name",
        description: "some description",  data_domain_id: data_domain.id,
        modifier: user.id, version_group_id: UUID.generate(),
        version: 1, content: content,
        last_change: DateTime.utc_now()
      }

      creation_attrs = Map.put(attrs, :content_schema, content_schema)
      assert {:error, %Ecto.Changeset{} = changeset} = BusinessConcepts.create_business_concept(creation_attrs)
      assert_expected_validation(changeset, "Field1", :inclusion)
    end

    test "create_business_concept/1 with invalid content: invalid variable list" do
      user = insert(:user)
      data_domain = insert(:data_domain)

      content_schema = [
        %{"name" => "Field1", "type" => "variable_list"},
      ]

      content = %{"Field1" => "World"}

      attrs = %{type: "some type", name: "some name",
        description: "some description",  data_domain_id: data_domain.id,
        modifier: user.id, version_group_id: UUID.generate(),
        version: 1, content: content,
        last_change: DateTime.utc_now()
      }

      creation_attrs = Map.put(attrs, :content_schema, content_schema)
      assert {:error, %Ecto.Changeset{} = changeset} = BusinessConcepts.create_business_concept(creation_attrs)
      assert_expected_validation(changeset, "Field1", :cast)
    end

    test "create_business_concept/1 with no content" do
      user = insert(:user)
      data_domain = insert(:data_domain)

      content_schema = [
        %{"name" => "Field1", "type" => "variable_list"},
      ]

      attrs = %{type: "some type", name: "some name",
        description: "some description",  data_domain_id: data_domain.id,
        modifier: user.id, version_group_id: UUID.generate(),
        version: 1,
        last_change: DateTime.utc_now()
      }

      creation_attrs = Map.put(attrs, :content_schema, content_schema)
      assert {:error, %Ecto.Changeset{} = changeset} = BusinessConcepts.create_business_concept(creation_attrs)
      assert_expected_validation(changeset, "content", :required)
    end

    test "create_business_concept/1 with nil content" do
      user = insert(:user)
      data_domain = insert(:data_domain)

      content_schema = [
        %{"name" => "Field1", "type" => "variable_list"},
      ]

      attrs = %{type: "some type", name: "some name",
        description: "some description",  data_domain_id: data_domain.id,
        modifier: user.id, version_group_id: UUID.generate(),
        version: 1, content: nil,
        last_change: DateTime.utc_now()
      }

      creation_attrs = Map.put(attrs, :content_schema, content_schema)
      assert {:error, %Ecto.Changeset{} = changeset} = BusinessConcepts.create_business_concept(creation_attrs)
      assert_expected_validation(changeset, "content", :required)
    end

    test "create_business_concept/1 with no content schema" do
      user = insert(:user)
      data_domain = insert(:data_domain)

      creation_attrs = %{type: "some type", name: "some name",
        description: "some description",  data_domain_id: data_domain.id,
        modifier: user.id, version_group_id: UUID.generate(),
        version: 1, content: %{},
        last_change: DateTime.utc_now()
      }

      assert_raise RuntimeError, "Content Schema is not defined for Business Concept", fn ->
        BusinessConcepts.create_business_concept(creation_attrs)
      end
    end

    test "update_business_concept/2 with valid data updates the business_concept" do
      user = insert(:user)
      business_concept = insert(:business_concept, modifier:  user.id)

      attrs = %{name: "some new name", description: "some new description", content: %{}}
      update_attrs = Map.put(attrs, :content_schema, [])

      assert {:ok, business_concept} = BusinessConcepts.update_business_concept(business_concept, update_attrs)
      assert %BusinessConcept{} = business_concept
      assert business_concept.name == attrs.name
      assert business_concept.description == attrs.description
    end

    test "update_business_concept/2 with valid content data updates the business_concept" do

      content_schema = [
        %{"name" => "Field1", "type" => "string", "required"=> true},
        %{"name" => "Field2", "type" => "string", "required"=> true},
      ]

      user = insert(:user)
      content = %{
        "Field1" => "First field",
        "Field2" => "Second field",
      }
      business_concept = insert(:business_concept, modifier:  user.id, content: content)

      update_content = %{
        "Field1" => "New first field"
      }
      update_attrs = %{
        content: update_content,
        content_schema: content_schema,
      }
      assert {:ok, business_concept} = BusinessConcepts.update_business_concept(business_concept, update_attrs)
      assert %BusinessConcept{} = business_concept
      assert business_concept.content["Field1"] == "New first field"
      assert business_concept.content["Field2"] == "Second field"
    end

    test "update_business_concept/2 with invalid data returns error changeset" do
      user = insert(:user)
      business_concept = insert(:business_concept, modifier:  user.id)

      update_attrs = %{name: nil, description: nil, version: nil, content: %{}, content_schema: []}
      assert {:error, %Ecto.Changeset{}} = BusinessConcepts.update_business_concept(business_concept, update_attrs)
      object = BusinessConcepts.get_business_concept!(business_concept.id)
      assert  object |> business_concept_preload() == business_concept
    end

    test "update_business_concept_status/2 with valid status data updates the business_concept" do
      user = insert(:user)
      business_concept = insert(:business_concept, modifier:  user.id)
      attrs = %{status: Atom.to_string(:published)}
      assert {:ok, business_concept} = BusinessConcepts.update_business_concept_status(business_concept, attrs)
      assert business_concept.status == Atom.to_string(:published)
    end

    test "reject_business_concept/2 rejects business_concept" do
      user = insert(:user)
      business_concept = insert(:business_concept,
                        status: BusinessConcept.status.pending_approval,
                        modifier:  user.id)
      attrs = %{reject_reason: "Because I want to"}
      assert {:ok, business_concept} = BusinessConcepts.reject_business_concept(business_concept, attrs)
      assert business_concept.status == BusinessConcept.status.rejected
      assert business_concept.reject_reason == attrs.reject_reason
    end

    test "delete_business_concept/1 deletes the business_concept" do
      user = insert(:user)
      business_concept = insert(:business_concept, modifier:  user.id)
      assert {:ok, %BusinessConcept{}} = BusinessConcepts.delete_business_concept(business_concept)
      assert_raise Ecto.NoResultsError, fn -> BusinessConcepts.get_business_concept!(business_concept.id) end
    end

    test "change_business_concept/1 returns a business_concept changeset" do
      user = insert(:user)
      business_concept = insert(:business_concept, modifier:  user.id)
      assert %Ecto.Changeset{} = BusinessConcepts.change_business_concept(business_concept)
    end
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
