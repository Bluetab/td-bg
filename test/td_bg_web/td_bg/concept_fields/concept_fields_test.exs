defmodule TdBg.ConceptFieldsTests do
  use TdBg.DataCase

  alias TdBg.ConceptFields
  alias Ecto.NoResultsError

  describe "concept_fields" do

    test "list_concept_fields/1 returns list of concept fields" do
      concept_field = insert(:concept_field)
      concept = concept_field.concept
      list = ConceptFields.list_concept_fields(concept)
      assert length(list) == 1
      assert list == [concept_field]
    end

    test "create_concept_field!/1 creates a concept field" do
      attrs = %{"concept" => "concept_id",
                "field" => %{}}
      {:ok, concept_field} = ConceptFields.create_concept_field(attrs)
      assert ConceptFields.get_concept_field!(concept_field.id)
    end

    test "delete_concept_field/1 deletes a concept field" do
      concept_field = insert(:concept_field)
      {:ok, _} = ConceptFields.delete_concept_field(concept_field)
      assert_raise NoResultsError, fn ->
        ConceptFields.get_concept_field!(concept_field.id)
      end
    end

  end
end
