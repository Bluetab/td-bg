defmodule TdBgWeb.BusinessConceptVersionSearchView do
  use TdBgWeb, :view
  use TdHypermedia, :view

  alias TdBgWeb.BusinessConceptVersionView

  def render("list.json", %{scroll_id: scroll_id} = assigns) do
    "list.json"
    |> render(Map.delete(assigns, :scroll_id))
    |> Map.put("scroll_id", scroll_id)
  end

  def render("list.json", %{hypermedia: hypermedia}) do
    render_many_hypermedia(hypermedia, BusinessConceptVersionView, "list_item.json")
  end

  def render("list.json", %{business_concept_versions: business_concept_versions}) do
    %{data: render_many(business_concept_versions, BusinessConceptVersionView, "list_item.json")}
  end
end
