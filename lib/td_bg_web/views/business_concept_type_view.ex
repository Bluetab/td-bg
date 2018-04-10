defmodule TdBgWeb.BusinessConceptTypeView do
  use TdBgWeb, :view
  alias TdBgWeb.BusinessConceptTypeView
  alias Ecto

  def render("index.json", %{business_concepts: business_concept_types}) do
    %{data: render_many(business_concept_types, BusinessConceptTypeView, "business_concept_type.json")}
  end

  def render("business_concept_type.json", %{business_concept_type: business_concept_type}) do
    %{type_name: business_concept_type}
  end

end
