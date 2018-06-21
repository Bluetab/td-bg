defmodule TdBg.Canada.TaxonomyAbilities do
  @moduledoc false
  alias TdBg.Accounts.User
  alias TdBg.Permissions
  alias TdBg.Permissions.AclEntry
  alias TdBg.Permissions.Permission
  alias TdBg.Taxonomies.Domain

  def can?(%User{id: user_id}, :list, Domain) do
    permissions = [
      Permission.permissions.create_domain,
      Permission.permissions.update_domain,
      Permission.permissions.delete_domain,
      Permission.permissions.create_acl_entry,
      Permission.permissions.update_acl_entry,
      Permission.permissions.delete_acl_entry
    ]

    Permissions.has_any_permission(user_id, permissions, Domain)
  end

  def can?(%User{id: user_id}, :create, %Domain{id: domain_id}) do
    %{user_id: user_id,
      permission: Permission.permissions.create_domain,
      domain_id: domain_id}
    |> Permissions.authorized?
  end

  def can?(%User{id: user_id}, :update, %Domain{id: domain_id}) do
    %{user_id: user_id,
      permission: Permission.permissions.update_domain,
      domain_id: domain_id}
    |> Permissions.authorized?
  end

  def can?(%User{id: user_id}, :show, %Domain{id: domain_id}) do
    %{user_id: user_id,
      permission: Permission.permissions.view_domain,
      domain_id: domain_id}
    |> Permissions.authorized?
  end

  def can?(%User{id: user_id}, :delete, %Domain{id: domain_id}) do
    %{user_id: user_id,
      permission: Permission.permissions.delete_domain,
      domain_id: domain_id}
    |> Permissions.authorized?
  end

  def can?( %User{id: user_id}, :create, %AclEntry{principal_type: "user", resource_type: "domain", resource_id: resource_id}) do
    %{user_id: user_id,
      permission: Permission.permissions.create_acl_entry,
      domain_id: resource_id}
    |> Permissions.authorized?
  end
end
