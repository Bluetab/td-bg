defmodule TdBg.BusinessConceptDataFieldsTests do
  use TdBg.DataCase

  alias TdBg.BusinessConceptDataFields
  alias Ecto.NoResultsError

  describe "business_concept_data_fields" do

    test "list_business_concept_data_fields!/1 returns list of business concept data fields" do
      business_concept_data_field = insert(:business_concept_data_field)
      business_concept = business_concept_data_field.business_concept
      list = BusinessConceptDataFields.list_business_concept_data_fields(business_concept)
      assert length(list) == 1
      assert list == [business_concept_data_field]
    end

    test "create_business_concept_data_field!/1 creates a business concept data field" do
      attrs = %{"business_concept" => "business_concept_id",
                "data_field" => "data_field_id"}
      {:ok, _} = BusinessConceptDataFields.create_business_concept_data_field(attrs)

      BusinessConceptDataFields.get_business_concept_data_field!(
        attrs["business_concept"], attrs["data_field"])
    end

    test "create_delete_business_concept_data_fields!/2 creates two business concepts" do
      attrs_first  = %{"business_concept" => "business_concept_first",
                       "data_field"       => "data_field_first"}
      attrs_second = %{"business_concept" => "business_concept_second",
                       "data_field"       => "data_field_second"}
      BusinessConceptDataFields.create_delete_business_concept_data_fields(
        [attrs_first, attrs_second], [])

      BusinessConceptDataFields.get_business_concept_data_field!(
        attrs_first["business_concept"], attrs_first["data_field"])
      BusinessConceptDataFields.get_business_concept_data_field!(
        attrs_second["business_concept"], attrs_second["data_field"])
    end

    test "delete_business_concept_data_field!/1 deletes a business concept data field" do
      attrs = %{"business_concept" => "business_concept_id",
                "data_field" => "data_field_id"}
      business_concept_data_field = insert(:business_concept_data_field,
        business_concept: attrs["business_concept"],
        data_field: attrs["data_field"])

      {:ok, _} = BusinessConceptDataFields.delete_business_concept_data_field(business_concept_data_field)

      assert_raise NoResultsError, fn ->
        BusinessConceptDataFields.get_business_concept_data_field!(
          attrs["business_concept"], attrs["data_field"])
      end
    end

    test "load_business_concept_data_fields!/2 no data fields" do
      assert {:ok_loading_data_fields, []} = BusinessConceptDataFields.load_business_concept_data_fields("123", [])
    end

    test "load_business_concept_data_fields!/2 add remove data fields" do
      business_concept = inspect(123)
      attrs_first  = %{"business_concept" => business_concept,
                       "data_field"       => "data_field_first"}
      attrs_second = %{"business_concept" => business_concept,
                       "data_field"       => "data_field_second"}
      attrs_third  = %{"business_concept" => business_concept,
                       "data_field"       => "data_field_third"}

      insert(:business_concept_data_field,
        business_concept: attrs_first["business_concept"],
        data_field: attrs_first["data_field"])

      insert(:business_concept_data_field,
        business_concept: attrs_second["business_concept"],
        data_field: attrs_second["data_field"])

      BusinessConceptDataFields.load_business_concept_data_fields(
        business_concept, [attrs_second["data_field"],
                           attrs_third["data_field"]])

      assert_raise NoResultsError, fn ->
        BusinessConceptDataFields.get_business_concept_data_field!(
          attrs_first["business_concept"], attrs_first["data_field"])
      end

      BusinessConceptDataFields.get_business_concept_data_field!(
        attrs_second["business_concept"], attrs_second["data_field"])

      BusinessConceptDataFields.get_business_concept_data_field!(
        attrs_third["business_concept"], attrs_third["data_field"])

    end

  end
end
