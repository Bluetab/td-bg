defmodule TdBgWeb.BusinessConceptFilterController do
  require Logger
  use TdBgWeb, :controller
  use PhoenixSwagger

  alias TdBgWeb.SwaggerDefinitions
  alias TdBg.BusinessConcept.Search
  alias Guardian.Plug, as: GuardianPlug

  action_fallback(TdBgWeb.FallbackController)

  def swagger_definitions do
    SwaggerDefinitions.filter_swagger_definitions()
  end

  swagger_path :index do
    get("/business_concept_filters")
    description("List Business Concept Filters")

    parameters do
    end

    response(200, "OK", Schema.ref(:FilterResponse))
  end

  def index(conn, _params) do
    user = get_current_user(conn)
    filters = Search.get_filter_values(user)
    render(conn, "show.json", filters: filters)
  end

  defp get_current_user(conn) do
    GuardianPlug.current_resource(conn)
  end
end
