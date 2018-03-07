defmodule TdBG.Canary.TaxonomyAbilities do
  @moduledoc false
  alias TdBG.Accounts.User
  alias TdBG.Taxonomies.DomainGroup
  alias TdBG.Taxonomies.DataDomain
  alias TdBG.Permissions
  alias TdBG.Permissions.AclEntry

  def can?(%User{id: user_id}, :create_data_domain, %DomainGroup{id: domain_group_id}) do
    has_admin_role(%{user_id: user_id, domain_group_id: domain_group_id})
  end

  def can?(%User{id: user_id}, :update, %DomainGroup{id: domain_group_id}) do
    has_admin_role(%{user_id: user_id, domain_group_id: domain_group_id})
  end

  def can?(%User{id: user_id}, :delete, %DomainGroup{id: domain_group_id}) do
    has_admin_role(%{user_id: user_id, domain_group_id: domain_group_id})
  end

  def can?(%User{id: user_id}, :update, %DataDomain{id: data_domain_id}) do
    has_admin_role(%{user_id: user_id, data_domain_id: data_domain_id})
  end

  def can?(%User{id: user_id}, :delete, %DataDomain{id: data_domain_id}) do
    has_admin_role(%{user_id: user_id, data_domain_id: data_domain_id})
  end

  def can?(%User{id: user_id}, :create, %DomainGroup{parent_id: parent_domain_group_id}) do
    if parent_domain_group_id == nil do
      false
    else
      has_admin_role(%{user_id: user_id, domain_group_id: parent_domain_group_id})
    end
  end

  def can?( %User{id: user_id}, :create, %AclEntry{principal_type: "user", resource_type: "data_domain", resource_id: resource_id}) do
    has_admin_role(%{user_id: user_id, data_domain_id: resource_id})
  end

  def can?( %User{id: user_id}, :create, %AclEntry{principal_type: "user", resource_type: "domain_group", resource_id: resource_id}) do
    has_admin_role(%{user_id: user_id, domain_group_id: resource_id})
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
