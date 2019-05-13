defmodule TdBgWeb.BusinessConceptAliasController do
  use TdBgWeb, :controller
  use TdBg.Hypermedia, :controller
  use PhoenixSwagger

  import Canada, only: [can?: 2]

  alias TdBg.BusinessConcepts
  alias TdBg.BusinessConcepts.BusinessConceptAlias
  alias TdBgWeb.ErrorView
  alias TdBgWeb.SwaggerDefinitions

  action_fallback(TdBgWeb.FallbackController)

  @search_service Application.get_env(:td_bg, :elasticsearch)[:search_service]

  def swagger_definitions do
    SwaggerDefinitions.business_concept_alias_definitions()
  end

  swagger_path :index do
    description("List Business Concept Aliases")

    parameters do
      business_concept_id(:path, :integer, "Business Concept ID", required: true)
    end

    response(200, "OK", Schema.ref(:BusinessConceptAliasesResponse))
  end

  def index(conn, %{"business_concept_id" => business_concept_id} = _params) do
    business_concept_aliases = BusinessConcepts.list_business_concept_aliases(business_concept_id)

    render(
      conn,
      "index.json",
      business_concept_aliases: business_concept_aliases,
      hypermedia:
        hypermedia("business_concept_business_concept_alias", conn, business_concept_aliases)
    )
  end

  swagger_path :create do
    description("Creates a Business Concept Alias")
    produces("application/json")

    parameters do
      business_concept_id(:path, :integer, "Business Concept ID", required: true)

      business_concept_alias(
        :body,
        Schema.ref(:BusinessConceptAliasCreate),
        "Business Concept Alias create attrs"
      )
    end

    response(200, "Created", Schema.ref(:BusinessConceptAliasResponse))
    response(400, "Client Error")
  end

  def create(conn, %{
        "business_concept_id" => business_concept_id,
        "business_concept_alias" => business_concept_alias_params
      }) do
    business_concept_version =
      BusinessConcepts.get_current_version_by_business_concept_id!(business_concept_id)

    concept_type = business_concept_version.business_concept.type
    alias_name = Map.get(business_concept_alias_params, "name")

    creation_attrs =
      business_concept_alias_params
      |> Map.put("business_concept_id", business_concept_id)

    user = conn.assigns[:current_user]

    with true <- can?(user, create_alias(business_concept_version)),
         {:name_available} <-
           BusinessConcepts.check_business_concept_name_availability(concept_type, alias_name),
         {:ok, %BusinessConceptAlias{} = business_concept_alias} <-
           BusinessConcepts.create_business_concept_alias(creation_attrs) do
      @search_service.put_search(business_concept_version)

      conn
      |> put_status(:created)
      |> put_resp_header(
        "location",
        Routes.business_concept_alias_path(conn, :show, business_concept_alias)
      )
      |> render("show.json", business_concept_alias: business_concept_alias)
    else
      false ->
        conn
        |> put_status(:forbidden)
        |> put_view(ErrorView)
        |> render("403.json")

      _error ->
        conn
        |> put_status(:unprocessable_entity)
        |> put_view(ErrorView)
        |> render("422.json")
    end
  end

  def show(conn, %{"id" => id}) do
    business_concept_alias = BusinessConcepts.get_business_concept_alias!(id)
    render(conn, "show.json", business_concept_alias: business_concept_alias)
  end

  swagger_path :delete do
    description("Deletes a Business Concept Alias")
    produces("application/json")

    parameters do
      business_concept_alias_id(:path, :integer, "Business Concept ID", required: true)
    end

    response(204, "No content")
    response(400, "Client Error")
  end

  def delete(conn, %{"id" => id}) do
    business_concept_alias = BusinessConcepts.get_business_concept_alias!(id)
    business_concept_id = business_concept_alias.business_concept_id

    business_concept_version =
      BusinessConcepts.get_current_version_by_business_concept_id!(business_concept_id)

    user = conn.assigns[:current_user]

    with true <- can?(user, delete_alias(business_concept_version)),
         {:ok, %BusinessConceptAlias{}} <-
           BusinessConcepts.delete_business_concept_alias(business_concept_alias) do
      @search_service.put_search(business_concept_version)
      send_resp(conn, :no_content, "")
    else
      false ->
        conn
        |> put_status(:forbidden)
        |> put_view(ErrorView)
        |> render("403.json")

      _error ->
        conn
        |> put_status(:unprocessable_entity)
        |> put_view(ErrorView)
        |> render("422.json")
    end
  end
end
