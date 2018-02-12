defmodule TrueBG.BusinessConceptsTests do
  use TrueBG.DataCase

  alias TrueBG.Repo
  alias TrueBG.BusinessConcepts

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

      content = %{
                  "Format" => "Date",
                  "Sensitive Data" => "Personal Data",
                  "Update Frequence" => "Not defined"
                  }

      attrs = %{type: "some type", name: "some name",
        description: "some description",  data_domain_id: data_domain.id,
        modifier: user.id, version: 1, content: content,
      }

      creation_attrs = Map.from_struct(build(:business_concept))
      creation_attrs = creation_attrs
        |> Map.merge(attrs)
        |> Map.merge(%{content_schema: bc_content_schema(:default)})

      assert {:ok, %BusinessConcept{} = business_concept} = BusinessConcepts.create_business_concept(creation_attrs)
      attrs
        |> Enum.each(&(assert business_concept |> Map.get(elem(&1, 0)) == elem(&1, 1)))
    end

    test "create_business_concept/1 with invalid data returns error changeset" do
      business_concept = build(:business_concept)
      creation_attrs = business_concept
        |> Map.from_struct()
        |> Map.put(:content_schema, bc_content_schema(:default))

      assert {:error, %Ecto.Changeset{}} = BusinessConcepts.create_business_concept(creation_attrs)
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
                        status: Atom.to_string(BusinessConcept.pending_approval),
                        modifier:  user.id)
      attrs = %{reject_reason: "Because I want to"}
      assert {:ok, business_concept} = BusinessConcepts.reject_business_concept(business_concept, attrs)
      assert business_concept.status == Atom.to_string(BusinessConcept.rejected)
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
end
