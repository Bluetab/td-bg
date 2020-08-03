defmodule TdBg.Canada.TaxonomyAbilities do
  @moduledoc false
  alias TdBg.Accounts.User
  alias TdBg.Permissions
  alias TdBg.Taxonomies.Domain

  def can?(%User{} = user, :list, Domain) do
    permissions = [
      :create_domain,
      :update_domain,
      :delete_domain,
      :create_acl_entry,
      :update_acl_entry,
      :delete_acl_entry,
      :view_domain
    ]

    Permissions.has_any_permission_on_resource_type?(user, permissions, Domain)
  end

  def can?(%User{} = user, :create, %Domain{id: domain_id}) do
    Permissions.authorized?(user, :create_domain, domain_id)
  end

  def can?(%User{} = user, :update, %Domain{id: domain_id}) do
    Permissions.authorized?(user, :update_domain, domain_id)
  end

  def can?(%User{} = user, :show, %Domain{id: domain_id}) do
    Permissions.authorized?(user, :view_domain, domain_id)
  end

  def can?(%User{} = user, :delete, %Domain{id: domain_id}) do
    Permissions.authorized?(user, :delete_domain, domain_id)
  end

  def can?(%User{} = user, :delete_link, %Domain{id: domain_id}) do
    Permissions.authorized?(user, :manage_business_concept_links, domain_id)
  end

  def can?(%User{} = user, :create_link, %Domain{id: domain_id}) do
    Permissions.authorized?(user, :manage_business_concept_links, domain_id)
  end

  def can?(%User{} = user, :move, %Domain{} = domain) do
    can?(user, :delete, domain) and can?(user, :update, domain)
  end
end
