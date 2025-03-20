defmodule TdBgWeb.BusinessConceptVersionSearchController do
  use TdBgWeb, :controller
  use TdHypermedia, :controller

  import Canada, only: [can?: 2]
  import Canada.Can, only: [can?: 3]

  alias TdBg.BusinessConcept.Search
  alias TdBg.BusinessConcepts.BusinessConceptVersion
  alias TdBg.BusinessConcepts.Links
  alias TdBgWeb.BusinessConceptVersionController

  require Logger

  action_fallback(TdBgWeb.FallbackController)

  def index(conn, %{"business_concept_id" => business_concept_id}) do
    claims = conn.assigns[:current_resource]

    %{"filters" => %{"business_concept_id" => String.to_integer(business_concept_id)}}
    |> Search.search_business_concept_versions(claims)
    |> render_search_results(conn)
  end

  def index(conn, params) do
    claims = conn.assigns[:current_resource]

    params
    |> Search.search_business_concept_versions(claims)
    |> render_search_results(conn)
  end

  def search(conn, params) do
    claims = conn.assigns[:current_resource]
    page = Map.get(params, "page", 0)
    size = Map.get(params, "size", 50)

    permission_by_status = get_permissions_by_status(params)

    include_links = Map.get(params, "include_links", false)

    results =
      %{results: business_concept_versions} =
      params
      |> Map.drop(["page", "size", "include_links"])
      |> Search.search_business_concept_versions(claims, page, size)

    bcv_with_links =
      business_concept_versions
      |> Enum.map(&add_links(&1, claims, include_links))
      |> Enum.map(&add_links_actions(&1, claims))

    results
    |> Map.put(:results, bcv_with_links)
    |> render_search_results(conn, permission_by_status)
  end

  def actions(conn, _params) do
    hypermedia =
      "business_concept_version"
      |> collection_hypermedia(conn, [], BusinessConceptVersion)
      |> put_actions(conn)

    render(conn, "list.json", hypermedia: hypermedia)
  end

  defp get_permissions_by_status(params) do
    status =
      params
      |> Map.get("must", %{})
      |> Map.get("status", [])

    cond do
      Enum.any?(status, &(&1 == "published")) ->
        :download_published_concepts

      Enum.any?(status, &(&1 == "deprecated")) ->
        :download_deprecated_concepts

      Enum.any?(status, &(&1 in ["draft", "pending_approval", "rejected"])) ->
        :download_draft_concepts

      true ->
        nil
    end
  end

  defp render_search_results(
         %{results: business_concept_versions, total: total} = assigns,
         conn,
         permission_by_status \\ nil
       ) do
    hypermedia =
      "business_concept_version"
      |> collection_hypermedia(
        conn,
        business_concept_versions,
        BusinessConceptVersion
      )
      |> put_actions(conn, permission_by_status)

    conn
    |> put_resp_header("x-total-count", "#{total}")
    |> render(
      "list.json",
      business_concept_versions: business_concept_versions,
      hypermedia: hypermedia,
      scroll_id: Map.get(assigns, :scroll_id)
    )
  end

  defp add_links(
         %{"business_concept_id" => business_concept_id} = business_concept_version,
         claims,
         true
       ) do
    links =
      business_concept_id
      |> Links.get_links()
      |> Enum.filter(fn link ->
        BusinessConceptVersionController.filter_link_by_permission(claims, link)
      end)

    Map.put(business_concept_version, "links", links)
  end

  defp add_links(business_concept_version, _claims, false),
    do: business_concept_version

  defp add_links_actions(business_concept_version, claims) do
    can_create_link = can?(claims, create_structure_link(business_concept_version))

    Map.put(business_concept_version, "_actions", %{
      "can_create_structure_link" => can_create_link
    })
  end

  defp put_actions(hypermedia, conn, permission_by_status \\ nil) do
    claims = conn.assigns[:current_resource]

    [:upload, :auto_publish, permission_by_status]
    |> Enum.filter(&can?(claims, &1, BusinessConceptVersion))
    |> Enum.map(fn action ->
      case action do
        :upload ->
          %TdHypermedia.Link{
            action: "upload",
            path: Routes.business_concept_version_path(conn, :upload),
            method: :POST,
            schema: %{}
          }

        :auto_publish ->
          %TdHypermedia.Link{
            action: "autoPublish",
            path: Routes.business_concept_version_path(conn, :upload),
            method: :POST,
            schema: %{}
          }

        ^permission_by_status ->
          %TdHypermedia.Link{
            action: normalize_action(action),
            method: :POST,
            schema: %{}
          }
      end
    end)
    |> then(
      &Map.put(
        hypermedia,
        :collection_hypermedia,
        Map.get(hypermedia, :collection_hypermedia) ++ &1
      )
    )
  end

  defp normalize_action(:download_published_concepts), do: "downloadPublishedConcepts"
  defp normalize_action(:download_draft_concepts), do: "downloadDraftConcepts"
  defp normalize_action(:download_deprecated_concepts), do: "downloadDeprecatedConcepts"
end
