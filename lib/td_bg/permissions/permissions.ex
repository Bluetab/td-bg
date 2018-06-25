defmodule TdBg.Permissions do
  @moduledoc """
  The Permissions context.
  """

  import Ecto.Query, warn: false

  alias Ecto.Changeset
  alias TdBg.Accounts.User
  alias TdBg.Permissions.AclEntry
  alias TdBg.Permissions.Permission
  alias TdBg.Permissions.Role
  alias TdBg.Repo
  alias TdBg.Taxonomies
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

  @doc """
    Returns Role with name role_name
  """
  def get_role_by_name(role_name) do
    Repo.get_by(Role, name: role_name)
  end

  def get_all_roles(%{user_id: user_id, domain_id: domain_id}) do
    domains = Taxonomies.get_ancestors_for_domain_id(domain_id, true)

    user = @td_auth_api.get_user(user_id)
    group_ids = User.get_group_ids(user)

    roles =
      domains
      |> Enum.flat_map(fn domain ->
        AclEntry.list_acl_entries(%{domain: domain}, role: [:permissions])
      end)
      |> Enum.filter(&AclEntry.acl_matches?(&1, user.id, group_ids))
      |> Enum.map(& &1.role)
      |> Enum.uniq_by(& &1.id)

    roles
  end

  def get_all_permissions(%{user_id: user_id, domain_id: domain_id}) do
    roles = get_all_roles(%{user_id: user_id, domain_id: domain_id})

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

  alias TdBg.Permissions.Role

  @doc """
  Returns the list of roles.

  ## Examples

      iex> list_roles()
      [%Role{}, ...]

  """
  def list_roles do
    Repo.all(Role)
  end

  @doc """
  Gets a single role.

  Raises `Ecto.NoResultsError` if the Role does not exist.

  ## Examples

      iex> get_role!(123)
      %Role{}

      iex> get_role!(456)
      ** (Ecto.NoResultsError)

  """
  def get_role!(id), do: Repo.get!(Role, id)

  @doc """
  Creates a role.

  ## Examples

      iex> create_role(%{field: value})
      {:ok, %Role{}}

      iex> create_role(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_role(attrs \\ %{}) do
    %Role{}
    |> Role.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a role.

  ## Examples

      iex> update_role(role, %{field: new_value})
      {:ok, %Role{}}

      iex> update_role(role, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_role(%Role{} = role, attrs) do
    role
    |> Role.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a Role.

  ## Examples

      iex> delete_role(role)
      {:ok, %Role{}}

      iex> delete_role(role)
      {:error, %Ecto.Changeset{}}

  """
  def delete_role(%Role{} = role) do
    Repo.delete(role)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking role changes.

  ## Examples

      iex> change_role(role)
      %Ecto.Changeset{source: %Role{}}

  """
  def change_role(%Role{} = role) do
    Role.changeset(role, %{})
  end

  @doc """
  Returns the list of Permissions asociated to a Role.

  ## Examples

      iex> get_role_permissions()
      [%Permission{}, ...]

  """
  def get_role_permissions(%Role{} = role) do
    role
    |> Repo.preload(:permissions)
    |> Map.get(:permissions)
  end

  @doc """
  Associate Permissions to a Role.

  ## Examples

      iex> add_permissions_to_role!()
      %Role{}

  """
  def add_permissions_to_role(%Role{} = role, permissions) do
    role
    |> Repo.preload(:permissions)
    |> Changeset.change()
    |> Changeset.put_assoc(:permissions, permissions)
    |> Repo.update!()
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
