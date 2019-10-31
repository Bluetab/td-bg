defmodule TdBgWeb.DomainView do
  use TdBgWeb, :view
  alias TdBgWeb.DomainView

  def render("index.json", %{domains: domains} = assigns) do
    with_actions(%{data: render_many(domains, DomainView, "domain.json")}, assigns)
  end

  def render("index_tiny.json", %{domains: domains}) do
    %{data: render_many(domains, DomainView, "domain_tiny.json")}
  end

  def render("show.json", %{domain: domain}) do
    with_actions(%{data: render_one(domain, DomainView, "domain.json")}, domain)
  end

  def render("domain.json", %{domain: domain}) do
    %{
      id: domain.id,
      parent_id: domain.parent_id,
      name: domain.name,
      type: domain.type,
      description: domain.description
    } |> with_actions(domain)
  end

  def render("domain_bc_count.json", %{counter: counter}) do
    %{data: %{counter: counter}}
  end

  def render("domain_tiny.json", %{domain: domain}) do
    %{id: domain.id, name: domain.name}
  end

  defp with_actions(struct, assigns) do
    actions = Map.take(assigns, [:_actions])
    Map.merge(struct, actions)
  end
end
