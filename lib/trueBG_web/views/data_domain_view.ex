defmodule TrueBGWeb.DataDomainView do
  use TrueBGWeb, :view
  alias TrueBGWeb.DataDomainView

  def render("index.json", %{data_domains: data_domains}) do
    %{data: render_many(data_domains, DataDomainView, "data_domain.json")}
  end

  def render("show.json", %{data_domain: data_domain}) do
    %{data: render_one(data_domain, DataDomainView, "data_domain.json")}
  end

  def render("data_domain.json", %{data_domain: data_domain}) do
    %{id: data_domain.id,
      name: data_domain.name,
      description: data_domain.description,
      domain_group_id: data_domain.domain_group_id
    }
  end

  def render("index_user_roles.json", %{users_roles: users_roles}) do
    %{data: render_many(users_roles, DataDomainView, "users_role.json")}
  end

  def render("users_role.json", %{data_domain: user_role}) do
    %{
      user: user_role.user,
      role: user_role.role
    }
  end
end
