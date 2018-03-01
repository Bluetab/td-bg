defmodule TrueBG.Canary.TaxonomyAbilities do
  @moduledoc false
  alias TrueBG.Accounts.User
  alias TrueBG.Taxonomies.DomainGroup
  alias TrueBG.Permissions
  alias TrueBG.Permissions.AclEntry

  def can?(%User{id: user_id}, :create_data_domain, %DomainGroup{id: domain_group_id}) do
    acl_params = %{user_id: user_id, domain_group_id: domain_group_id}
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

  def can?(%User{id: user_id}, :update, %DomainGroup{id: domain_group_id}) do
    acl_params = %{user_id: user_id, domain_group_id: domain_group_id}
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

  def can?(%User{id: user_id}, :create, %DomainGroup{parent_id: parent_domain_group_id}) do
    acl_params = %{user_id: user_id, domain_group_id: parent_domain_group_id}
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

  def can?( %User{id: user_id}, :create, %AclEntry{principal_type: "user", resource_type: "domain_group", resource_id: resource_id}) do
    acl_params = %{user_id: user_id, domain_group_id: resource_id}
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
