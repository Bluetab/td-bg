defmodule TdBgWeb.BusinessConceptTypeController do
  require Logger
  use TdBgWeb, :controller
  use PhoenixSwagger


  alias TdBg.BusinessConcepts
  alias TdBgWeb.SwaggerDefinitions

  action_fallback TdBgWeb.FallbackController

  def swagger_definitions do
    SwaggerDefinitions.business_concept_type_definitions()
  end

  swagger_path :index do
    get "/business_concept_types"
    description "List Business Concepts Types"
    response 200, "OK", Schema.ref(:BusinessConceptTypesResponse)
  end

  def index(conn, _params) do
    business_concept_types = BusinessConcepts.list_business_concept_types()
    render(conn, "index.json", business_concepts: business_concept_types)
  end

end
