defmodule TrueBGWeb.BusinessConceptController do
  use TrueBGWeb, :controller

  import Canada

  alias TrueBG.Taxonomies
  alias TrueBG.Taxonomies.BusinessConcept
  alias TrueBG.Taxonomies.DataDomain

  alias TrueBG.Auth.Guardian.Plug, as: GuardianPlug
  alias Poison, as: JSON

  plug :load_and_authorize_resource, model: DataDomain, persisted: true, only: :create

  action_fallback TrueBGWeb.FallbackController

  defp get_current_user(conn) do
    GuardianPlug.current_resource(conn)
  end

  def index(conn, _params) do
    business_concepts = Taxonomies.list_business_concepts()
    render(conn, "index.json", business_concepts: business_concepts)
  end

  defp do_create(conn, user,  business_concept_params) do
    type = business_concept_params |> Map.get("type")
    filename = Application.get_env(:trueBG, :bc_schema_location)
    content_schema = filename
      |> File.read!
      |> JSON.decode!
      |> Map.get(type)

    business_concept_params = business_concept_params
      |> Map.put("content_schema", content_schema)
      |> Map.put("modifier", user.id)
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

  def create(conn, %{"id" => data_domain_id, "business_concept" => business_concept_params}) do
    user = conn |> get_current_user
    business_concept_params = business_concept_params
      |> Map.put("data_domain_id", data_domain_id)
    do_create(conn, user, business_concept_params)
  end

  def show(conn, %{"id" => id}) do
    business_concept = Taxonomies.get_business_concept!(id)
    render(conn, "show.json", business_concept: business_concept)
  end

  def update(conn, %{"id" => id, "business_concept" => business_concept_params}) do
    business_concept = Taxonomies.get_business_concept!(id)

    with {:ok, %BusinessConcept{} = business_concept} <- Taxonomies.update_business_concept(business_concept, business_concept_params) do
      render(conn, "show.json", business_concept: business_concept)
    end
  end

  def delete(conn, %{"id" => id}) do
    business_concept = Taxonomies.get_business_concept!(id)
    with {:ok, %BusinessConcept{}} <- Taxonomies.delete_business_concept(business_concept) do
      send_resp(conn, :no_content, "")
    end
  end
end
