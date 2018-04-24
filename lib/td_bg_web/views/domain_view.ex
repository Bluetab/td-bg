defmodule TdBgWeb.DomainView do
  use TdBgWeb, :view
  alias TdBgWeb.DomainView
  use TdBg.Hypermedia, :view

  def render("index.json", %{domains: domains, hypermedia: hypermedia}) do
    %{data: render_many_hypermedia(domains,
      hypermedia, DomainView, "domain.json")}
  end
  def render("index.json", %{domains: domains}) do
    %{data: render_many(domains, DomainView, "domain.json")}
  end

  def render("show.json", %{domain: domain, hypermedia: hypermedia}) do
    %{data: render_one_hypermedia(domain,
      hypermedia, DomainView, "domain.json")}
  end
  def render("show.json", %{domain: domain}) do
    %{data: render_one(domain, DomainView, "domain.json")}
  end

  def render("domain.json", %{domain: domain}) do
    %{id: domain.id,
      parent_id: domain.parent_id,
      name: domain.name,
      type: domain.type,
      description: domain.description}
  end

  def render("index_user_roles.json", %{users_roles: users_roles, hypermedia: hypermedia}) do
    %{data: render_many_hypermedia(users_roles,
    hypermedia, DomainView, "users_role.json")}
  end
  def render("index_user_roles.json", %{users_roles: users_roles}) do
    %{data: render_many(users_roles, DomainView, "users_role.json")}
  end

  def render("users_role.json", %{domain: user_role}) do
    %{
      user_id: user_role.user_id,
      user_name: user_role.user_name,
      role_name: user_role.role_name,
      role_id: user_role.role_id,
      acl_entry_id: user_role.acl_entry_id
    }
  end
end
