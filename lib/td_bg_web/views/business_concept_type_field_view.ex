defmodule TdBgWeb.BusinessConceptTypeFieldView do
  use TdBgWeb, :view
  alias TdBgWeb.BusinessConceptTypeFieldView
  alias Ecto

  def render("index.json", %{business_concept_type_fields: business_concept_type_fields}) do
    %{data: render_many(business_concept_type_fields, BusinessConceptTypeFieldView, "business_concept_type_field.json")}
  end

  def render("business_concept_type_field.json", %{business_concept_type_field: business_concept_type_field}) do
    %{name: business_concept_type_field["name"],
      type: business_concept_type_field["type"],
      max_size: business_concept_type_field["max_size"],
      values: business_concept_type_field["values"],
      required: business_concept_type_field["required"],
      default: business_concept_type_field["default"],
      group: business_concept_type_field["group"]
    }
  end

end
