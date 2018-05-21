defmodule TdBg.Canary.TaxonomyAbilities do
  @moduledoc false
  alias TdBg.Accounts.User
  alias TdBg.Taxonomies.Domain
  alias TdBg.Permissions
  alias TdBg.Permissions.Permission
  alias TdBg.Permissions.AclEntry

  def can?(%User{id: user_id}, :create, %Domain{parent_id: parent_id, id: domain_id}) do
    if parent_id == nil do
      false
    else
      %{user_id: user_id,
        permission: Permission.permissions.create_domain,
        domain_id: domain_id}
      |> Permissions.authorized?
    end
  end

  def can?(%User{id: user_id}, :update, %Domain{id: domain_id}) do
    %{user_id: user_id,
      permission: Permission.permissions.update_domain,
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
