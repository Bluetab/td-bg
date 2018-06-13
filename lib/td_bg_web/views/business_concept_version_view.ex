defmodule TdBgWeb.BusinessConceptVersionView do
  use TdBgWeb, :view
  use TdBg.Hypermedia, :view

  alias TdBgWeb.BusinessConceptVersionView
  alias TdBgWeb.DomainView

  def render("index.json", %{
        business_concept_versions: business_concept_versions,
        hypermedia: hypermedia
      }) do
    render_many_hypermedia(
      business_concept_versions,
      hypermedia,
      BusinessConceptVersionView,
      "business_concept_version.json"
    )
  end

  def render("index.json", %{business_concept_versions: business_concept_versions}) do
    %{
      data:
        render_many(
          business_concept_versions,
          BusinessConceptVersionView,
          "business_concept_version.json"
        )
    }
  end

  def render("show.json", %{
        business_concept_version: business_concept_version,
        hypermedia: hypermedia
      }) do
    render_one_hypermedia(
      business_concept_version,
      hypermedia,
      BusinessConceptVersionView,
      "business_concept_version.json"
    )
  end

  def render("show.json", %{business_concept_version: business_concept_version}) do
    %{
      data:
        render_one(
          business_concept_version,
          BusinessConceptVersionView,
          "business_concept_version.json"
        )
    }
  end

  def render("list.json", %{
        business_concept_versions: business_concept_versions,
        hypermedia: hypermedia
      }) do
    render_many_hypermedia(
      business_concept_versions,
      hypermedia,
      BusinessConceptVersionView,
      "list_item.json"
    )
  end

  def render("list.json", %{business_concept_versions: business_concept_versions}) do
    %{data: render_many(business_concept_versions, BusinessConceptVersionView, "list_item.json")}
  end

  def render("list_item.json", %{business_concept_version: business_concept_version}) do
    view_fields = ["id", "name", "description", "domain", "status"]
    test_fields = ["business_concept_id", "current", "type", "version"]
    Map.take(business_concept_version, view_fields ++ test_fields)
  end

  def render("business_concept_version.json", %{
        business_concept_version: business_concept_version
      }) do
    %{
      id: business_concept_version.id,
      business_concept_id: business_concept_version.business_concept.id,
      type: business_concept_version.business_concept.type,
      content: business_concept_version.content,
      related_to: business_concept_version.related_to,
      name: business_concept_version.name,
      description: business_concept_version.description,
      last_change_by: business_concept_version.last_change_by,
      last_change_at: business_concept_version.last_change_at,
      domain: Map.take(business_concept_version.business_concept.domain, [:id, :name]),
      status: business_concept_version.status,
      current: business_concept_version.current,
      version: business_concept_version.version
    }
    |> add_reject_reason(
      business_concept_version.reject_reason,
      String.to_atom(business_concept_version.status)
    )
    |> add_mod_comments(
      business_concept_version.mod_comments,
      business_concept_version.version
    )
    |> add_aliases(business_concept_version.business_concept)
  end

  def render(
        "index_business_concept_taxonomy.json",
        %{business_concept_taxonomy: business_concept_taxonomy}
      ) do
    %{
      data:
        render_many(
          business_concept_taxonomy,
          BusinessConceptVersionView,
          "business_concept_taxonomy_entry.json"
        )
    }
  end

  def render(
        "business_concept_taxonomy_entry.json",
        %{business_concept_version: business_concept_version}
      ) do
    %{
      domain_id: business_concept_version.domain_id,
      domain_name: business_concept_version.domain_name,
      roles: render_many(business_concept_version.roles, DomainView, "acl_entry.json")
    }
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
      alias_array = Enum.map(business_concept.aliases, &%{id: &1.id, name: &1.name})
      Map.put(concept, :aliases, alias_array)
    else
      concept
    end
  end
end
