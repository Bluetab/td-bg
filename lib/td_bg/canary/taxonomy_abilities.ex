defmodule TdBg.Canary.TaxonomyAbilities do
  @moduledoc false
  alias TdBg.Accounts.User
  alias TdBg.Taxonomies.Domain
  alias TdBg.Permissions
  alias TdBg.Permissions.Permission
  alias TdBg.Permissions.AclEntry
  alias TdBg.Repo

  def can?(%User{id: user_id}, :create, %Domain{parent_id: parent_id}) do
    if parent_id == nil do
      false
    else
      %{user_id: user_id,
        action: Permission.permissions.create_domain,
        domain_id: parent_id}
      |> allowed_action?
    end
  end

  def can?(%User{id: user_id}, :update, %Domain{id: domain_id}) do
    %{user_id: user_id,
      action: Permission.permissions.update_domain,
      domain_id: domain_id}
    |> allowed_action?
  end

  def can?(%User{id: user_id}, :delete, %Domain{id: domain_id}) do
    %{user_id: user_id,
      action: Permission.permissions.delete_domain,
      domain_id: domain_id}
    |> allowed_action?
  end

  def can?( %User{id: user_id}, :create, %AclEntry{principal_type: "user", resource_type: "domain", resource_id: resource_id}) do
    %{user_id: user_id,
      action: Permission.permissions.create_acl_entry,
      domain_id: resource_id}
    |> allowed_action?
  end

  defp allowed_action?(%{user_id: user_id, action: action, domain_id: domain_id}) do
    acl_input = %{user_id: user_id, domain_id: domain_id}
    role_name = Permissions.get_role_in_resource(acl_input)
    role = Permissions.get_role_by_name(role_name.name)
    case role do
      nil -> false
      _ ->
        role
        |> Repo.preload(:permissions)
        |> Map.get(:permissions)
        |> Enum.map(&(&1.name))
        |> Enum.member?(action)
    end
  end

end
