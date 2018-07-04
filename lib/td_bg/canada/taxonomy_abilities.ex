defmodule TdBg.Canada.TaxonomyAbilities do
  @moduledoc false
  alias TdBg.Accounts.User
  alias TdBg.Permissions
  alias TdBg.Permissions.AclEntry
  alias TdBg.Permissions.Permission
  alias TdBg.Taxonomies.Domain

  def can?(%User{} = user, :list, Domain) do
    # TODO: Migrate to td_perms
    permissions = [
      Permission.permissions.create_domain,
      Permission.permissions.update_domain,
      Permission.permissions.delete_domain,
      Permission.permissions.create_acl_entry,
      Permission.permissions.update_acl_entry,
      Permission.permissions.delete_acl_entry
    ]

    Permissions.has_any_permission(user, permissions, Domain)
  end

  def can?(%User{} = user, :create, %Domain{id: domain_id}) do
    Permissions.authorized?(user, Permission.permissions.create_domain, domain_id)
  end

  def can?(%User{} = user, :update, %Domain{id: domain_id}) do
    Permissions.authorized?(user, Permission.permissions.update_domain, domain_id)
  end

  def can?(%User{} = user, :show, %Domain{id: domain_id}) do
    Permissions.authorized?(user, Permission.permissions.view_domain, domain_id)
  end

  def can?(%User{} = user, :delete, %Domain{id: domain_id}) do
    Permissions.authorized?(user, Permission.permissions.delete_domain, domain_id)
  end

  def can?(%User{} = user, :create, %AclEntry{principal_type: "user", resource_type: "domain", resource_id: domain_id}) do
    Permissions.authorized?(user, Permission.permissions.create_acl_entry, domain_id)
  end
end
