defmodule TdBgWeb.SharedDomainController do
  use TdBgWeb, :controller
  import Canada, only: [can?: 2]

  alias TdBg.BusinessConcepts
  alias TdBg.BusinessConcepts.BusinessConcept
  alias TdBgWeb.BusinessConceptView

  action_fallback(TdBgWeb.FallbackController)

  def update(conn, %{"business_concept_id" => id} = params) do
    claims = conn.assigns[:current_resource]
    domain_ids = Map.get(params, "domain_ids", [])

    with %BusinessConcept{} = concept <- BusinessConcepts.get_business_concept(id),
         {:can, true} <- {:can, can?(claims, share_with_domain(concept))},
         {:ok, %{updated: updated}} <- BusinessConcepts.share(concept, domain_ids) do
      conn
      |> put_status(200)
      |> put_view(BusinessConceptView)
      |> render(
        "show.json",
        business_concept: updated
      )
    else
      nil -> {:error, :not_found}
      error -> error
    end
  end
end
