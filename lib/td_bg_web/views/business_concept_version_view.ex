defmodule TdBgWeb.BusinessConceptVersionView do
  use TdBgWeb, :view
  use TdHypermedia, :view

  alias TdBg.BusinessConcepts.BusinessConceptVersion
  alias TdBgWeb.{BusinessConceptVersionView, DomainView, LinkView}
  alias TdCache.UserCache
  alias TdDfLib.Content
  alias TdDfLib.Format

  def render(
        "show.json",
        %{business_concept_version: business_concept_version, links_hypermedia: links_hypermedia} =
          assigns
      ) do
    %{"data" => links} = render_many_hypermedia(links_hypermedia, LinkView, "embedded.json")
    shared_to = render_shared_to(assigns)

    render_one(
      business_concept_version,
      BusinessConceptVersionView,
      "show.json",
      assigns
      |> Map.delete(:links_hypermedia)
      |> Map.put("_embedded", %{links: links, shared_to: shared_to})
    )
  end

  def render(
        "show.json",
        %{
          business_concept_version: business_concept_version,
          hypermedia: hypermedia
        } = assigns
      ) do
    render_one_hypermedia(
      business_concept_version,
      hypermedia,
      BusinessConceptVersionView,
      "business_concept_version.json",
      Map.drop(assigns, [:business_concept_version, :hypermedia])
    )
  end

  def render("show.json", %{business_concept_version: business_concept_version} = assigns) do
    %{
      data:
        render_one(
          business_concept_version,
          BusinessConceptVersionView,
          "business_concept_version.json",
          Map.drop(assigns, [:business_concept_version])
        )
    }
  end

  def render(
        "business_concept_version.json",
        %{business_concept_version: business_concept_version} = assigns
      ) do
    {:ok, user} = UserCache.get(business_concept_version.last_change_by)

    {last_change_at, last_change_by} =
      BusinessConceptVersion.get_last_change(business_concept_version)

    %{
      id: business_concept_version.id,
      business_concept_id: business_concept_version.business_concept.id,
      type: business_concept_version.business_concept.type,
      content: business_concept_version.content,
      confidential: business_concept_version.business_concept.confidential,
      completeness: Map.get(business_concept_version, :completeness),
      name: business_concept_version.name,
      last_change_by: last_change_by,
      last_change_at: last_change_at,
      domain: Map.take(business_concept_version.business_concept.domain, [:id, :name]),
      status: business_concept_version.status,
      current: business_concept_version.current,
      version: business_concept_version.version,
      in_progress: business_concept_version.in_progress,
      last_change_user: user,
      rule_count: Map.get(business_concept_version, :rule_count),
      link_count: Map.get(business_concept_version, :link_count),
      concept_count: Map.get(business_concept_version, :concept_count),
      domain_parents: Map.get(business_concept_version, :domain_parents)
    }
    |> add_reject_reason(
      business_concept_version.reject_reason,
      String.to_atom(business_concept_version.status)
    )
    |> add_mod_comments(
      business_concept_version.mod_comments,
      business_concept_version.version
    )
    |> add_template(assigns)
    |> add_embedded_resources(assigns)
    |> add_cached_content(assigns)
    |> add_actions(assigns)
    |> maybe_add_i18n_content(business_concept_version)
    |> Content.legacy_content_support(:content)
  end

  defp add_reject_reason(concept, reject_reason, :rejected) do
    Map.put(concept, :reject_reason, reject_reason)
  end

  defp add_reject_reason(concept, _reject_reason, _status), do: concept

  defp add_mod_comments(concept, _mod_comments, 1), do: concept

  defp add_mod_comments(concept, mod_comments, _version) do
    Map.put(concept, :mod_comments, mod_comments)
  end

  defp add_template(concept, assigns) do
    case Map.get(assigns, :template, nil) do
      nil ->
        concept

      template ->
        template_view = Map.take(template, [:content, :label])
        Map.put(concept, :template, template_view)
    end
  end

  defp add_cached_content(concept, assigns) do
    case Map.get(assigns, :template) do
      nil ->
        concept

      template ->
        content =
          concept
          |> Map.get(:content)
          |> Format.enrich_content_values(template, [:system, :hierarchy])

        Map.put(concept, :content, content)
    end
  end

  defp render_shared_to(%{shared_to: shared_to}) do
    render_many(shared_to, DomainView, "domain.json")
  end

  defp render_shared_to(_assigns), do: []

  defp add_actions(concept, %{actions: actions = %{}}) do
    Map.put(concept, :actions, actions)
  end

  defp add_actions(concept, _assigns), do: concept

  defp maybe_add_i18n_content(concept, %{i18n_content: i18n_content}) do
    result =
      Enum.reduce(i18n_content, %{}, fn %{lang: lang} = data, acc ->
        Map.put(acc, "#{lang}", Map.take(data, [:content, :name, :completeness]))
      end)

    Map.put(concept, :i18n_content, result)
  end

  defp maybe_add_i18n_content(concept, _bcv), do: concept
end
