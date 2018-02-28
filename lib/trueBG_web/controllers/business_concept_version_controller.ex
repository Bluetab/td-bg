defmodule TrueBGWeb.BusinessConceptVersionController do
  use TrueBGWeb, :controller

  alias TrueBG.BusinessConcepts

  action_fallback TrueBGWeb.FallbackController

  def index(conn, _params) do
    business_concept_versions = BusinessConcepts.list_business_concept_versions()
    render(conn, "index.json", business_concept_versions: business_concept_versions)
  end

  def show(conn, %{"id" => id}) do
    business_concept_version = BusinessConcepts.get_business_concept_version!(id)
    render(conn, "show.json", business_concept_version: business_concept_version)
  end
end
