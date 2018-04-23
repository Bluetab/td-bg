defmodule TdBg.Canary.TaxonomyAbilities do
  @moduledoc false
  alias TdBg.Accounts.User
  alias TdBg.Taxonomies.Domain
  alias TdBg.Permissions
  alias TdBg.Permissions.AclEntry

  def can?(%User{id: user_id}, :create, %Domain{parent_id: parent_id}) do
    if parent_id == nil do
      false
    else
      has_admin_role(%{user_id: user_id, domain_id: parent_id})
    end
  end

  def can?(%User{id: user_id}, :update, %Domain{id: domain_id}) do
    has_admin_role(%{user_id: user_id, domain_id: domain_id})
  end

  def can?(%User{id: user_id}, :delete, %Domain{id: domain_id}) do
    has_admin_role(%{user_id: user_id, domain_id: domain_id})
  end

  def can?( %User{id: user_id}, :create, %AclEntry{principal_type: "user", resource_type: "domain", resource_id: resource_id}) do
    has_admin_role(%{user_id: user_id, domain_id: resource_id})
  end

  defp has_admin_role(acl_params) do
    role = Permissions.get_role_in_resource(acl_params)
    case role.name do
      "admin" ->
        true
      name when name in ["watcher" , "creator", "publisher"] ->
        false
      _ ->
        false
    end
  end
end
