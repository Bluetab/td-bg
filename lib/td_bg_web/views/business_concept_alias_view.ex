defmodule TdBgWeb.BusinessConceptAliasView do
  use TdBgWeb, :view
  alias TdBgWeb.BusinessConceptAliasView

  def render("index.json", %{business_concept_aliases: business_concept_aliases}) do
    %{data: render_many(business_concept_aliases, BusinessConceptAliasView, "business_concept_alias.json")}
  end

  def render("show.json", %{business_concept_alias: business_concept_alias}) do
    %{data: render_one(business_concept_alias, BusinessConceptAliasView, "business_concept_alias.json")}
  end

  def render("business_concept_alias.json", %{business_concept_alias: business_concept_alias}) do
    %{id: business_concept_alias.id,
      business_concept_id: business_concept_alias.business_concept_id,
      name: business_concept_alias.name}
  end
end
