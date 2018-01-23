defmodule TrueBGWeb.DomainGroupView do
  use TrueBGWeb, :view
  alias TrueBGWeb.DomainGroupView

  def render("index.json", %{domain_groups: domain_groups}) do
    %{data: render_many(domain_groups, DomainGroupView, "domain_group.json")}
  end

  def render("show.json", %{domain_group: domain_group}) do
    %{data: render_one(domain_group, DomainGroupView, "domain_group.json")}
  end

  def render("domain_group.json", %{domain_group: domain_group}) do
    %{id: domain_group.id,
      parent_id: domain_group.parent_id,
      name: domain_group.name,
      description: domain_group.description}
  end
end
