defmodule TdBg.Permissions do
  @moduledoc """
  The Permissions context.
  """

  import Ecto.Query, warn: false

  alias TdBg.Accounts.User
  alias TdBg.Permissions.AclEntry
  alias TdBg.Permissions.Permission
  alias TdBg.Repo
  alias TdBg.Taxonomies.Domain

  @td_auth_api Application.get_env(:td_bg, :auth_service)[:api_service]

  @doc """
  Returns the list of permissions.

  ## Examples

      iex> list_permissions()
      [%Permission{}, ...]

  """
  def list_permissions do
    Repo.all(Permission)
  end

  @doc """
  Gets a single permission.

  Raises `Ecto.NoResultsError` if the Permission does not exist.

  ## Examples

      iex> get_permissions!(123)
      %Permission{}

      iex> get_permissions!(456)
      ** (Ecto.NoResultsError)

  """
  def get_permission!(id), do: Repo.get!(Permission, id)

  def get_resource_type_permissions(%{user_id: user_id}, resource_type) do
    %{user_id: user_id}
    |> AclEntry.list_acl_entries_by_user_with_groups()
    |> Enum.filter(&(&1.resource_type == resource_type))
    |> Enum.map(&%{resource_id: &1.resource_id, permissions: &1.role.permissions})
  end

  def get_domain_permissions(%{user_id: user_id}) do
    get_resource_type_permissions(%{user_id: user_id}, "domain")
  end

  def get_all_permissions(%{user_id: user_id, domain_id: domain_id}) do
    roles = AclEntry.get_all_roles(%{user_id: user_id, domain_id: domain_id})

    roles
    |> Enum.flat_map(& &1.permissions)
    |> Enum.uniq_by(& &1.id)
    |> Enum.map(& &1.name)
  end

  def has_any_group_permission(user_id, permissions, Domain) do
    user = @td_auth_api.get_user(user_id)
    group_ids = User.get_group_ids(user)

    query =
      from(
        a in AclEntry,
        join: r in assoc(a, :role),
        join: p in assoc(r, :permissions),
        where:
          p.name in ^permissions and a.principal_id in ^group_ids and a.principal_type == "group",
        limit: 1,
        select: a
      )

    group_acl = query |> Repo.one()

    if group_acl do
      true
    else
      false
    end
  end

  def has_any_permission(user_id, permissions, Domain) do
    query =
      from(
        a in AclEntry,
        join: r in assoc(a, :role),
        join: p in assoc(r, :permissions),
        where:
          p.name in ^permissions and a.principal_id == ^user_id and a.principal_type == "user",
        limit: 1,
        select: a
      )

    user_acl = query |> Repo.one()

    if user_acl do
      true
    else
      has_any_group_permission(user_id, permissions, Domain)
    end
  end

  @doc """
  Return array of user permissions in a resource

  ## Examples

      iex> get_permissions_in_resource?()
      true

  """
  def get_permissions_in_resource(%{user_id: user_id, domain_id: domain_id}) do
    acl_input = %{user_id: user_id, domain_id: domain_id}

    acl_input
    |> get_all_permissions()
  end

  def get_permissions_in_resource_cache(%{user_id: user_id, domain_id: domain_id}) do
    cache_key = %{user_id: user_id, domain_id: domain_id}

    ConCache.get_or_store(:permissions_cache, cache_key, fn ->
      get_permissions_in_resource(cache_key)
    end)
  end

  @doc """
  Check if user has a permission in a domain.

  ## Examples

      iex> authorized?()
      true

  """
  def authorized?(%{user_id: user_id, permission: permission, domain_id: domain_id}) do
    %{user_id: user_id, domain_id: domain_id}
    |> get_permissions_in_resource_cache
    |> Enum.member?(permission)
  end
end
