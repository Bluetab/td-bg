defmodule TdBg.Permissions do
  @moduledoc """
  The Permissions context.
  """

  import Ecto.Query, warn: false

  alias TdBg.Accounts.User
  alias TdBg.Permissions.AclEntry
  alias TdBg.Permissions.Permission
  alias TdBg.Repo
  alias TdBg.Taxonomies
  alias TdBg.Taxonomies.Domain

  @permission_resolver Application.get_env(:td_bg, :permission_resolver)

  def get_domain_permissions(%User{jti: jti}) do
    @permission_resolver.get_acls_by_resource_type(jti, "domain")
  end

  def has_any_permission(%User{} = user, permissions, Domain) do
    session_permissions = get_or_store_session_permissions(user)
    session_permissions
      |> Enum.filter(&(&1.resource_type == "domain"))
      |> Enum.flat_map(&(&1.permissions))
      |> Enum.uniq
      |> Enum.any?(&(Enum.member?(permissions, &1)))
  end

  def get_or_store_session_permissions(%User{id: id, jti: jti, gids: gids}) do
    ConCache.get_or_store(:session_permissions, jti, fn ->
      %{user_id: id, gids: gids}
        |> AclEntry.list_acl_entries_by_user_with_groups
        |> Enum.map(&(acl_entry_to_permissions/1))
    end)
  end

  defp acl_entry_to_permissions(%{resource_type: resource_type, resource_id: resource_id, role: %{permissions: permissions}}) do
    permission_names = permissions |> Enum.map(&(&1.name))
    %{resource_type: resource_type, resource_id: resource_id, permissions: permission_names}
  end

  @doc """
  Check if user has a permission in a domain.

  ## Examples

      iex> authorized?(%User{}, "create", 12)
      false

  """
  def authorized?(%User{jti: jti}, permission, domain_id) do
    domain_id
      |> Taxonomies.get_parent_ids(true)
      |> Enum.any?(&(@permission_resolver.has_permission?(jti, permission, "domain", &1)))
  end

end
