defmodule TdBgWeb.DomainView do
  use TdBgWeb, :view
  alias TdBgWeb.DomainView
  alias TdBgWeb.GroupView
  alias TdBgWeb.UserView
  alias TdBg.Accounts.User
  alias TdBg.Accounts.Group
  use TdBg.Hypermedia, :view

  def render("index.json", %{domains: domains, hypermedia: hypermedia}) do
    render_many_hypermedia(domains, hypermedia, DomainView, "domain.json")
  end
  def render("index.json", %{domains: domains}) do
    %{data: render_many(domains, DomainView, "domain.json")}
  end

  def render("show.json", %{domain: domain, hypermedia: hypermedia}) do
    render_one_hypermedia(domain, hypermedia, DomainView, "domain.json")
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

  def render("index_acl_entries.json", %{acl_entries: acl_entries, hypermedia: hypermedia}) do
    render_many_hypermedia(acl_entries, hypermedia, DomainView, "acl_entry.json")
  end
  def render("index_acl_entries.json", %{acl_entries: acl_entries}) do
    %{data: render_many(acl_entries, DomainView, "acl_entry.json")}
  end

  def render("user_domain_entry.json", %{domain: user_domain_entry}) do
    %{
      id: user_domain_entry.id,
      domain_name: user_domain_entry.name
    }
  end

  def render("acl_entry.json", %{domain: acl_entry}) do
    %{
      principal: render_principal(acl_entry.principal),
      principal_type: acl_entry.principal_type,
      role_name: acl_entry.role_name,
      role_id: acl_entry.role_id,
      acl_entry_id: acl_entry.acl_entry_id
    }
  end

  def render("acl_entry_show.json", %{acl_entry: acl_entry}) do
    %{data:
      %{id: acl_entry.id,
        principal_type: acl_entry.principal_type,
        principal_id: acl_entry.principal_id,
        resource_type: acl_entry.resource_type,
        resource_id: acl_entry.resource_id,
        role_id: acl_entry.role_id
      }
    }
  end

  def render_principal(%Group{} = group) do
    render_one(group, GroupView, "group.json")

  end
  def render_principal(%User{} = user) do
    render_one(user, UserView, "user.json")
  end
end
