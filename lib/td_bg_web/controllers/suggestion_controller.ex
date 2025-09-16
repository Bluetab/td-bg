defmodule TdBgWeb.SuggestionController do
  use TdBgWeb, :controller
  import Canada, only: [can?: 2]

  alias TdBg.BusinessConcepts.BusinessConcept
  alias TdBg.BusinessConcepts.Search.Suggestions
  alias TdBgWeb.BusinessConceptVersionSearchView
  alias TdBgWeb.ErrorView

  action_fallback(TdBgWeb.FallbackController)

  def search(conn, params) do
    claims = conn.assigns[:current_resource]

    if can?(claims, suggest_concepts(BusinessConcept)) do
      results = Suggestions.knn(claims, params)

      conn
      |> put_view(BusinessConceptVersionSearchView)
      |> render("list.json", business_concept_versions: results)
    else
      conn
      |> put_status(:forbidden)
      |> put_view(ErrorView)
      |> render("403.json")
    end
  end
end
