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
      :delete_acl_entry
    ]

    Permissions.has_any_permission?(user, permissions, Domain)
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

end
