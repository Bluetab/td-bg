defmodule TdBgWeb.DomainView do
  use TdBgWeb, :view
  alias TdBgWeb.DomainView
  use TdHypermedia, :view

  def render("index.json", %{hypermedia: hypermedia}) do
    render_many_hypermedia(hypermedia, DomainView, "domain.json")
  end

  def render("index.json", %{domains: domains}) do
    %{data: render_many(domains, DomainView, "domain.json")}
  end

  def render("show.json", %{
        domain: domain,
        parentable_ids: parentable_ids,
        hypermedia: hypermedia
      }) do
    parentable_ids
    |> case do
      [] -> domain
      ids -> Map.put(domain, :parentable_ids, ids)
    end
    |> render_one_hypermedia(hypermedia, DomainView, "domain.json")
  end

  def render("show.json", %{domain: domain, hypermedia: hypermedia}) do
    render_one_hypermedia(domain, hypermedia, DomainView, "domain.json")
  end

  def render("show.json", %{domain: domain}) do
    %{data: render_one(domain, DomainView, "domain.json")}
  end

  def render("domain.json", %{domain: domain}) do
    domain
    |> Map.take([
      :id,
      :parent_id,
      :name,
      :type,
      :external_id,
      :description,
      :parentable_ids,
      :domain_group,
      :parents
    ])
    |> with_group()
    |> with_parents()
  end

  def render("domain_bc_count.json", %{counter: counter}) do
    %{data: %{counter: counter}}
  end

  defp with_group(%{domain_group: domain_group} = domain) when not is_nil(domain_group) do
    Map.put(domain, :domain_group, Map.take(domain_group, [:id, :name, :status]))
  end

  defp with_group(domain), do: domain

  defp with_parents(%{parents: parents} = domain) when is_list(parents) do
    %{domain | parents: Enum.map(parents, &Map.take(&1, [:id, :external_id, :name]))}
  end

  defp with_parents(domain), do: domain
end
