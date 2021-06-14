defmodule TdBgWeb.SharedDomainController do
  use TdBgWeb, :controller
  import Canada, only: [can?: 2]
  use PhoenixSwagger
  alias TdBg.BusinessConcepts
  alias TdBg.BusinessConcepts.BusinessConcept
  alias TdBgWeb.BusinessConceptView

  action_fallback(TdBgWeb.FallbackController)

  swagger_path :update do
    description("Updates domain relations to a business concept")

    parameters do
      business_concept_id(:path, :integer, "Business Id", required: true)
      domain_ids(:body, :array, "List of domain ids")
    end

    response(200, "OK", Schema.ref(:BusinessConceptResponse))
  end

  def update(conn, %{"business_concept_id" => id} = params) do
    claims = conn.assigns[:current_resource]
    domain_ids = Map.get(params, "domain_ids", [])

    with %BusinessConcept{} = concept <- BusinessConcepts.get_business_concept(id),
         {:can, true} <- {:can, can?(claims, update(concept))},
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
