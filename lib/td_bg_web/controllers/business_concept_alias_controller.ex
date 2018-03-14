defmodule TdBgWeb.BusinessConceptAliasController do
  use TdBgWeb, :controller
  use PhoenixSwagger

  import Canada, only: [can?: 2]

  alias TdBg.BusinessConcepts
  alias TdBg.BusinessConcepts.BusinessConceptAlias
  alias TdBgWeb.SwaggerDefinitions
  alias Guardian.Plug, as: GuardianPlug
  alias TdBgWeb.ErrorView

  action_fallback TdBgWeb.FallbackController

  def swagger_definitions do
    SwaggerDefinitions.business_concept_alias_definitions()
  end

  swagger_path :index do
    get "/business_concepts/{business_concept_id}/aliases"
    description "List Business Concept Aliases"
    parameters do
      id :path, :integer, "Business Concept ID", required: true
    end
    response 200, "OK", Schema.ref(:BusinessConceptAliasesResponse)
  end

  def index(conn, %{"business_concept_id" => business_concept_id} = _params) do
    business_concept_aliases = BusinessConcepts.list_business_concept_aliases(business_concept_id)
    render(conn, "index.json", business_concept_aliases: business_concept_aliases)
  end

  swagger_path :create do
    post "/business_concepts/{business_concept_id}/aliases"
    description "Creates a Business Concept Alias"
    produces "application/json"
    parameters do
      business_concept_alias :body, Schema.ref(:BusinessConceptAliasCreate), "Business Concept Alias create attrs"
    end
    response 200, "Created", Schema.ref(:BusinessConceptAliasResponse)
    response 400, "Client Error"
  end

  def create(conn, %{"business_concept_id" => business_concept_id, "business_concept_alias" => business_concept_alias_params}) do

    business_concept_version = BusinessConcepts.get_current_version_by_business_concept_id!(business_concept_id)
    concept_type = business_concept_version.business_concept.type
    alias_name = Map.get(business_concept_alias_params, "name")
    creation_attrs = business_concept_alias_params
    |> Map.put("business_concept_id", business_concept_id)

    user = get_current_user(conn)
    with true <- can?(user, create_alias(business_concept_version)),
         {:available} <- BusinessConcepts.check_business_concept_name_availability(concept_type, alias_name),
         {:ok, %BusinessConceptAlias{} = business_concept_alias} <- BusinessConcepts.create_business_concept_alias(creation_attrs) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", business_concept_alias_path(conn, :show, business_concept_alias))
      |> render("show.json", business_concept_alias: business_concept_alias)
    else
      false ->
        conn
        |> put_status(:forbidden)
        |> render(ErrorView, :"403.json")
      _error ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ErrorView, :"422.json")
    end
  end

  def show(conn, %{"id" => id}) do
    business_concept_alias = BusinessConcepts.get_business_concept_alias!(id)
    render(conn, "show.json", business_concept_alias: business_concept_alias)
  end

  def delete(conn, %{"id" => id}) do
    business_concept_alias = BusinessConcepts.get_business_concept_alias!(id)
    business_concept_id = business_concept_alias.business_concept_id
    business_concept_version = BusinessConcepts.get_current_version_by_business_concept_id!(business_concept_id)

    user = get_current_user(conn)
    with true <- can?(user, delete_alias(business_concept_version)),
         {:ok, %BusinessConceptAlias{}} <- BusinessConcepts.delete_business_concept_alias(business_concept_alias) do
      send_resp(conn, :no_content, "")
    else
      false ->
        conn
        |> put_status(:forbidden)
        |> render(ErrorView, :"403.json")
      _error ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ErrorView, :"422.json")
    end
  end

  defp get_current_user(conn) do
    GuardianPlug.current_resource(conn)
  end

end
