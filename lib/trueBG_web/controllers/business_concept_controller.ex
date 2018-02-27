defmodule TrueBGWeb.BusinessConceptController do
  use TrueBGWeb, :controller

  import Canada, only: [can?: 2]

  alias TrueBG.BusinessConcepts
  alias TrueBG.BusinessConcepts.BusinessConcept
  alias TrueBG.BusinessConcepts.BusinessConceptVersion
  alias TrueBG.Taxonomies.DataDomain
  alias TrueBGWeb.ErrorView

  alias Poison, as: JSON

  plug :load_resource, model: DataDomain, id_name: "data_domain_id", persisted: true, only: :create

  action_fallback TrueBGWeb.FallbackController

  def index(conn, _params) do
    business_concepts = BusinessConcepts.list_business_concepts()
    render(conn, "index.json", business_concepts: business_concepts)
  end

  def index_children_business_concept(conn, %{"id" => id}) do
    business_concepts = BusinessConcepts.list_children_business_concept(id)
    render(conn, "index.json", business_concepts: business_concepts)
  end

  def create(conn, %{"business_concept" => business_concept_params}) do

    concept_type = Map.get(business_concept_params, "type")
    content_schema = get_content_schema(concept_type)

    concept_name = Map.get(business_concept_params, "name")

    user = conn.assigns.current_user
    data_domain = conn.assigns.data_domain

    business_concept_attrs = %{}
    |> Map.put("data_domain_id", data_domain.id)
    |> Map.put("type", concept_type)
    |> Map.put("last_change_by", user.id)
    |> Map.put("last_change_at", DateTime.utc_now())

    creation_attrs = business_concept_params
    |> Map.put("business_concept", business_concept_attrs)
    |> Map.put("content_schema", content_schema)
    |> Map.put("last_change_by", conn.assigns.current_user.id)
    |> Map.put("last_change_at", DateTime.utc_now())
    |> Map.put("status", BusinessConcept.status.draft)
    |> Map.put("version", 1)

    with true <- can?(user, create_business_concept(data_domain)),
         {:ok, 0} <- count_business_concepts(concept_type, concept_name),
         {:ok, %BusinessConceptVersion{} = concept} <-
          BusinessConcepts.create_business_concept(creation_attrs) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", business_concept_path(conn, :show, concept.business_concept))
      |> render("show.json", business_concept: concept)
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
    business_concept = BusinessConcepts.get_business_concept!(id)
    render(conn, "show.json", business_concept: business_concept)
  end

  def update(conn, %{"id" => id, "business_concept" => business_concept_params}) do
    business_concept_version = BusinessConcepts.get_business_concept!(id)
    status_draft = BusinessConcept.status.draft
    status_published = BusinessConcept.status.published
    case business_concept_version.status do
      ^status_draft ->
        update_draft(conn, business_concept_version, business_concept_params)
      ^status_published ->
        update_published(conn, business_concept_version, business_concept_params)
    end

  end

  defp update_draft(conn, business_concept_version, business_concept_params) do
    concept_type = business_concept_version.business_concept.type
    concept_name = Map.get(business_concept_params, "name")
    content_schema = get_content_schema(concept_type)

    user = conn.assigns.current_user

    business_concept_attrs = %{}
    |> Map.put("last_change_by", user.id)
    |> Map.put("last_change_at", DateTime.utc_now())

    update_params = business_concept_params
    |> Map.put("business_concept", business_concept_attrs)
    |> Map.put("content_schema", content_schema)
    |> Map.put("last_change_by", user.id)
    |> Map.put("last_change_at", DateTime.utc_now())

    count = if concept_name == business_concept_version.name, do: 1, else: 0
    with true <- can?(user, update(business_concept_version)),
         {:ok, ^count} <- count_business_concepts(concept_type, concept_name),
         {:ok, %BusinessConceptVersion{} = concept} <-
      BusinessConcepts.update_business_concept(business_concept_version,
                                                              update_params) do
      render(conn, "show.json", business_concept: concept)
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

  defp update_published(conn, business_concept_version, business_concept_params)  do
    business_concept = business_concept_version.business_concept
    concept_type = business_concept.type
    content_schema = get_content_schema(concept_type)

    user = conn.assigns.current_user

    business_concept = business_concept
    |> Map.put("last_change_by", user.id)
    |> Map.put("last_change_at", DateTime.utc_now())

    draft_attrs = Map.from_struct(business_concept_version)
    draft_attrs = draft_attrs
    |> Map.merge(business_concept_params)
    |> Map.put("business_concept", business_concept)
    |> Map.put("content_schema", content_schema)
    |> Map.put("last_change_by", user.id)
    |> Map.put("last_change_at", DateTime.utc_now())
    |> Map.put("mod_comments", business_concept_params["mod_comments"])
    |> Map.put("status", BusinessConcept.status.draft)
    |> Map.put("version", business_concept_version.version + 1)

    with true <- can?(user, update(business_concept_version)),
         {:ok, %BusinessConceptVersion{} = draft} <-
           BusinessConcepts.create_business_concept(draft_attrs) do
      render(conn, "show.json", business_concept: draft)
    else
      false ->
        conn
        |> put_status(:forbidden)
        |> render(ErrorView, :"403.json")
      __error ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ErrorView, :"422.json")
    end
  end

  defp get_content_schema(content_type) do
    filename = Application.get_env(:trueBG, :bc_schema_location)
    filename
      |> File.read!
      |> JSON.decode!
      |> Map.get(content_type)
  end

  defp count_business_concepts(type, name) do
    BusinessConcepts.count_business_concepts(type, name,
                                      [BusinessConcept.status.draft,
                                       BusinessConcept.status.published])
  end
end
