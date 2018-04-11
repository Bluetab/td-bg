defmodule TdBgWeb.BusinessConceptTypeFieldController do
  require Logger
  use TdBgWeb, :controller
  use PhoenixSwagger

  alias TdBg.BusinessConcepts
  alias TdBgWeb.SwaggerDefinitions

  action_fallback TdBgWeb.FallbackController

  def swagger_definitions do
    SwaggerDefinitions.business_concept_type_fields_definitions()
  end

  swagger_path :index do
    get "/business_concept_type_fields?business_concept_type={bc_type}"
    parameters do
      bc_type :path, :string, "Business Concept Type name", required: true
    end
    description "List Business Concept Type Fields"
    response 200, "OK", Schema.ref(:BusinessConceptTypeFieldsResponse)
  end

  def index(conn, %{"business_concept_type" => bc_type}) do
    business_concept_type_fields = BusinessConcepts.list_business_concept_type_fields(bc_type)
    render(conn, "index.json", business_concept_type_fields: business_concept_type_fields)
  end

end
