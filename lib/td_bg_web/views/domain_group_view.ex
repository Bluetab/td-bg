defmodule TdBgWeb.DomainGroupView do
  use TdBgWeb, :view
  alias TdBgWeb.DomainGroupView
  use TdBg.Hypermedia, :view

  def render("index.json", %{domain_groups: domain_groups, hypermedia: hypermedia}) do
    %{data: render_many_hypermedia(domain_groups,
      hypermedia, DomainGroupView, "domain_group.json")}
  end
  def render("index.json", %{domain_groups: domain_groups}) do
    %{data: render_many(domain_groups, DomainGroupView, "domain_group.json")}
  end

  def render("show.json", %{domain_group: domain_group, hypermedia: hypermedia}) do
    %{data: render_one_hypermedia(domain_group,
      hypermedia, DomainGroupView, "domain_group.json")}
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

  def render("index_user_roles.json", %{users_roles: users_roles, hypermedia: hypermedia}) do
    %{data: render_many_hypermedia(users_roles,
    hypermedia, DomainGroupView, "users_role.json")}
  end
  def render("index_user_roles.json", %{users_roles: users_roles}) do
    %{data: render_many(users_roles, DomainGroupView, "users_role.json")}
  end

  def render("users_role.json", %{domain_group: user_role}) do
    %{
      user_id: user_role.user_id,
      user_name: user_role.user_name,
      role_name: user_role.role_name,
      role_id: user_role.role_id
    }
  end
end
