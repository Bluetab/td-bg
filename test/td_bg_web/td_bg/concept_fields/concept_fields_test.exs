defmodule TdBg.ConceptFieldsTests do
  use TdBg.DataCase

  alias TdBg.ConceptFields
  alias Ecto.NoResultsError

  describe "concept_fields" do

    test "list_concept_fields!/1 returns list of concept fields" do
      concept_field = insert(:concept_field)
      concept = concept_field.concept
      list = ConceptFields.list_concept_fields(concept)
      assert length(list) == 1
      assert list == [concept_field]
    end

    test "create_concept_field!/1 creates a concept field" do
      attrs = %{"concept" => "concept_id",
                "field" => "field_id"}
      {:ok, _} = ConceptFields.create_concept_field(attrs)

      ConceptFields.get_concept_field!(
        attrs["concept"], attrs["field"])
    end

    test "create_delete_concept_fields!/2 creates two business concepts" do
      attrs_first  = %{"concept" => "concept_first",
                       "field"       => "field_first"}
      attrs_second = %{"concept" => "concept_second",
                       "field"       => "field_second"}
      ConceptFields.create_delete_concept_fields(
        [attrs_first, attrs_second], [])

      ConceptFields.get_concept_field!(
        attrs_first["concept"], attrs_first["field"])
      ConceptFields.get_concept_field!(
        attrs_second["concept"], attrs_second["field"])
    end

    test "delete_concept_field!/1 deletes a concept field" do
      attrs = %{"concept" => "concept_id",
                "field" => "field_id"}
      concept_field = insert(:concept_field,
        concept: attrs["concept"],
        field: attrs["field"])

      {:ok, _} = ConceptFields.delete_concept_field(concept_field)

      assert_raise NoResultsError, fn ->
        ConceptFields.get_concept_field!(
          attrs["concept"], attrs["field"])
      end
    end

    test "load_concept_fields!/2 no data fields" do
      assert {:ok_loading_fields, []} = ConceptFields.load_concept_fields("123", [])
    end

    test "load_concept_fields!/2 add remove data fields" do
      concept = inspect(123)
      attrs_first  = %{"concept" => concept,
                       "field"       => "field_first"}
      attrs_second = %{"concept" => concept,
                       "field"       => "field_second"}
      attrs_third  = %{"concept" => concept,
                       "field"       => "field_third"}

      insert(:concept_field,
        concept: attrs_first["concept"],
        field: attrs_first["field"])

      insert(:concept_field,
        concept: attrs_second["concept"],
        field: attrs_second["field"])

      ConceptFields.load_concept_fields(
        concept, [attrs_second["field"],
                           attrs_third["field"]])

      assert_raise NoResultsError, fn ->
        ConceptFields.get_concept_field!(
          attrs_first["concept"], attrs_first["field"])
      end

      ConceptFields.get_concept_field!(
        attrs_second["concept"], attrs_second["field"])

      ConceptFields.get_concept_field!(
        attrs_third["concept"], attrs_third["field"])

    end

  end
end
