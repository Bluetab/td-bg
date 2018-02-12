defmodule TrueBGWeb.BusinessConceptController do
  use TrueBGWeb, :controller

  alias TrueBG.Taxonomies
  alias TrueBG.Taxonomies.BusinessConcept
  alias TrueBG.Taxonomies.DataDomain

  alias Poison, as: JSON

  plug :load_canary_action, phoenix_action: :create, canary_action: :create_business_concept
  plug :load_and_authorize_resource, model: DataDomain, id_name: "data_domain_id", persisted: true, only: :create_business_concept

  plug :load_and_authorize_resource, model: BusinessConcept, only: [:update, :publish, :send_for_approval]

  action_fallback TrueBGWeb.FallbackController

  def index(conn, _params) do
    business_concepts = Taxonomies.list_business_concepts()
    render(conn, "index.json", business_concepts: business_concepts)
  end

  def index_children_business_concept(conn, %{"id" => id}) do
    business_concepts = Taxonomies.list_children_business_concept(id)
    render(conn, "index.json", business_concepts: business_concepts)
  end

  def create(conn, %{"business_concept" => business_concept_params}) do

    content_type = Map.get(business_concept_params, "type")
    content_schema = get_content_schema(content_type)

    business_concept_params = business_concept_params
      |> Map.put("data_domain_id", conn.assigns.data_domain.id)
      |> Map.put("content_schema", content_schema)
      |> Map.put("modifier", conn.assigns.current_user.id)
      |> Map.put("last_change", DateTime.utc_now())
      |> Map.put("status", Atom.to_string(BusinessConcept.draft))
      |> Map.put("version", 1)

    with {:ok, %BusinessConcept{} = business_concept} <- Taxonomies.create_business_concept(business_concept_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", business_concept_path(conn, :show, business_concept))
      |> render("show.json", business_concept: business_concept)
    end
  end

  def show(conn, %{"id" => id}) do
    business_concept = Taxonomies.get_business_concept!(id)
    render(conn, "show.json", business_concept: business_concept)
  end

  def update(conn, %{"id" => id, "business_concept" => business_concept_params}) do
    business_concept = Taxonomies.get_business_concept!(id)
    content_schema = get_content_schema(business_concept.type)
    business_concept_params = Map.put(business_concept_params, "content_schema", content_schema)

    with {:ok, %BusinessConcept{} = business_concept} <- Taxonomies.update_business_concept(business_concept, business_concept_params) do
      render(conn, "show.json", business_concept: business_concept)
    end
  end

  def publish(conn, _params) do
    business_concept = conn.assigns.business_concept
    attrs = %{status: Atom.to_string(:published)}
    with {:ok, %BusinessConcept{} = business_concept} <-
          Taxonomies.update_business_concept_status(business_concept, attrs) do
      render(conn, "show.json", business_concept: business_concept)
    end
  end

  def send_for_approval(conn, _parmas) do
    business_concept = conn.assigns.business_concept
    attrs = %{status: Atom.to_string(:pending_approval)}
    with {:ok, %BusinessConcept{} = business_concept} <-
          Taxonomies.update_business_concept_status(business_concept, attrs) do
      render(conn, "show.json", business_concept: business_concept)
    end
  end

  def delete(conn, %{"id" => id}) do
    business_concept = Taxonomies.get_business_concept!(id)
    with {:ok, %BusinessConcept{}} <- Taxonomies.delete_business_concept(business_concept) do
      send_resp(conn, :no_content, "")
    end
  end

  defp get_content_schema(content_type) do
    filename = Application.get_env(:trueBG, :bc_schema_location)
    filename
      |> File.read!
      |> JSON.decode!
      |> Map.get(content_type)
  end
end
