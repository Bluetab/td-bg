defmodule TrueBGWeb.BusinessConceptVersionController do
  use TrueBGWeb, :controller

  import Canada, only: [can?: 2]

  alias TrueBG.BusinessConcepts
  alias TrueBG.BusinessConcepts.BusinessConcept
  alias TrueBG.BusinessConcepts.BusinessConceptVersion
  alias Poison, as: JSON
  alias TrueBGWeb.ErrorView

  action_fallback TrueBGWeb.FallbackController

  def index(conn, _params) do
    business_concept_versions = BusinessConcepts.list_business_concept_versions()
    render(conn, "index.json", business_concept_versions: business_concept_versions)
  end

  def create(conn, %{"business_concept_id" => business_concept_id, "business_concept" => business_concept_params}) do
    business_concept_version = BusinessConcepts.get_current_version_by_business_concept_id!(business_concept_id)
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

    with true <- can?(user, update_published(business_concept_version)),
         {:ok, %BusinessConceptVersion{} = new_version} <- BusinessConcepts.create_business_concept_version(draft_attrs) do
      render(conn, "show.json", business_concept_version: new_version)
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

  def show(conn, %{"id" => id}) do
    business_concept_version = BusinessConcepts.get_business_concept_version!(id)
    render(conn, "show.json", business_concept_version: business_concept_version)
  end

  defp get_content_schema(content_type) do
    filename = Application.get_env(:trueBG, :bc_schema_location)
    filename
      |> File.read!
      |> JSON.decode!
      |> Map.get(content_type)
  end

end
