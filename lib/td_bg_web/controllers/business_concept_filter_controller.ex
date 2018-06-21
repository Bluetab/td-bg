defmodule TdBgWeb.BusinessConceptFilterController do
  require Logger
  use TdBgWeb, :controller
  use PhoenixSwagger

  alias TdBgWeb.SwaggerDefinitions
  alias TdBg.BusinessConcept.Search

  action_fallback(TdBgWeb.FallbackController)

  def swagger_definitions do
    SwaggerDefinitions.filter_swagger_definitions()
  end

  swagger_path :index do
    get("/business_concept_filters")
    description("List Business Concept Filters")
    response(200, "OK", Schema.ref(:FilterResponse))
  end

  def index(conn, _params) do
    user = conn.assigns[:current_user]
    filters = Search.get_filter_values(user)
    render(conn, "show.json", filters: filters)
  end

end
