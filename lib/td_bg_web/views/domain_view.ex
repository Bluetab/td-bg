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

  def render("index_tiny.json", %{domains: domains}) do
    %{data: render_many(domains, DomainView, "domain_tiny.json")}
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
    Map.take(domain, [:id, :parent_id, :name, :type, :external_id, :description, :parentable_ids])
  end

  def render("domain_bc_count.json", %{counter: counter}) do
    %{data: %{counter: counter}}
  end

  def render("domain_tiny.json", %{domain: domain}) do
    %{id: domain.id, name: domain.name}
  end
end
