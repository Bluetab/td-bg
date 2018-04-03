defmodule TdBgWeb.BusinessConceptView do
  use TdBgWeb, :view
  alias TdBgWeb.BusinessConceptView
  alias Ecto

  def render("index.json", %{business_concepts: business_concept_versions}) do
    %{data: render_many(business_concept_versions, BusinessConceptView, "business_concept.json")}
  end

  def render("show.json", %{business_concept: business_concept_versions}) do
    %{data: render_one(business_concept_versions, BusinessConceptView, "business_concept.json")}
  end

  def render("business_concept.json", %{business_concept: business_concept_version}) do
    %{id: business_concept_version.business_concept.id,
      business_concept_version_id: business_concept_version.id,
      type: business_concept_version.business_concept.type,
      content: business_concept_version.content,
      related_to: business_concept_version.related_to,
      name: business_concept_version.name,
      description: business_concept_version.description,
      last_change_by: business_concept_version.last_change_by,
      last_change_at: business_concept_version.last_change_at,
      data_domain_id: business_concept_version.business_concept.data_domain_id,
      status: business_concept_version.status,
      version: business_concept_version.version}
    |> add_reject_reason(business_concept_version.reject_reason,
                         String.to_atom(business_concept_version.status))
    |> add_mod_comments(business_concept_version.mod_comments,
                        business_concept_version.version)
    |> add_aliases(business_concept_version.business_concept)
  end

  def render("business_concept_aliases.json", %{business_concept_aliases: business_concept_aliases}) do
    render_many(business_concept_aliases, BusinessConceptView, "business_concept_alias.json")
  end

  def render("business_concept_alias.json", %{business_concept_alias: business_concept_alias}) do
    %{id: business_concept_alias.id,
      name: business_concept_alias.name}
  end

  def render("search.json", %{business_concepts: business_concept_versions}) do
    %{data: render_many(business_concept_versions, BusinessConceptView, "search_item.json")}
  end

  def render("search_item.json", %{business_concept: business_concept_version}) do
    %{id: business_concept_version.business_concept.id,
      name: business_concept_version.name}
  end

  defp add_reject_reason(concept, reject_reason, :rejected) do
    Map.put(concept, :reject_reason, reject_reason)
  end
  defp add_reject_reason(concept, _reject_reason, _status), do: concept

  defp add_mod_comments(concept, _mod_comments, 1), do: concept
  defp add_mod_comments(concept, mod_comments, _version) do
    Map.put(concept, :mod_comments, mod_comments)
  end

  defp add_aliases(concept, business_concept) do
    if Ecto.assoc_loaded?(business_concept.aliases) do
      alias_array = render("business_concept_aliases.json", %{business_concept_aliases: business_concept.aliases})
      Map.put(concept, :aliases, alias_array)
    else
      concept
    end
  end

end
