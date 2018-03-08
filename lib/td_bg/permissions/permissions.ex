defmodule TdBg.Permissions do
  @moduledoc """
  The Permissions context.
  """

  import Ecto.Query, warn: false
  alias TdBg.Repo

  alias TdBg.Permissions.AclEntry
  alias TdBg.Permissions.Role
  alias TdBg.Taxonomies.DataDomain
  alias TdBg.Taxonomies.DomainGroup
  alias TdBg.Taxonomies

  @doc """
  Returns the list of acl_entries.

  ## Examples

      iex> list_acl_entries()
      [%Acl_entry{}, ...]

  """
  def list_acl_entries do
    Repo.all(AclEntry)
  end

  @doc """
    Returns a list of users-role with acl_entries in the data_domain passed as argument
  """
  def list_acl_entries(%{data_domain: data_domain}) do
    acl_entries = Repo.all(from acl_entry in AclEntry, where: acl_entry.resource_type == "data_domain" and acl_entry.resource_id == ^data_domain.id)
    acl_entries |> Repo.preload(:role)
  end

  @doc """

  """
  def get_acl_entry_by_principal_and_resource(%{user_id: principal_id, domain_group: domain_group}) do
    Repo.get_by(AclEntry, principal_type: "user", principal_id: principal_id, resource_type: "domain_group", resource_id: domain_group.id)
  end

  @doc """

  """
  def get_acl_entry_by_principal_and_resource(%{user_id: principal_id, data_domain: data_domain}) do
    Repo.get_by(AclEntry, principal_type: "user", principal_id: principal_id, resource_type: "data_domain", resource_id: data_domain.id)
  end

  @doc """
  Gets a single acl_entry.

  Raises `Ecto.NoResultsError` if the Acl entry does not exist.

  ## Examples

      iex> get_acl_entry!(123)
      %Acl_entry{}

      iex> get_acl_entry!(456)
      ** (Ecto.NoResultsError)

  """
  def get_acl_entry!(id), do: Repo.get!(AclEntry, id)

  @doc """
  Creates a acl_entry.

  ## Examples

      iex> create_acl_entry(%{field: value})
      {:ok, %Acl_entry{}}

      iex> create_acl_entry(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_acl_entry(attrs \\ %{}) do
    %AclEntry{}
    |> AclEntry.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a acl_entry.

  ## Examples

      iex> update_acl_entry(acl_entry, %{field: new_value})
      {:ok, %Acl_entry{}}

      iex> update_acl_entry(acl_entry, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_acl_entry(%AclEntry{} = acl_entry, attrs) do
    acl_entry
    |> AclEntry.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a Acl_entry.

  ## Examples

      iex> delete_acl_entry(acl_entry)
      {:ok, %Acl_entry{}}

      iex> delete_acl_entry(acl_entry)
      {:error, %Ecto.Changeset{}}

  """
  def delete_acl_entry(%AclEntry{} = acl_entry) do
    Repo.delete(acl_entry)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking acl_entry changes.

  ## Examples

      iex> change_acl_entry(acl_entry)
      %Ecto.Changeset{source: %Acl_entry{}}

  """
  def change_acl_entry(%AclEntry{} = acl_entry) do
    AclEntry.changeset(acl_entry, %{})
  end

  @doc """
    Returns Role with name role_name
  """
  def get_role_by_name(role_name) do
    Repo.get_by(Role, name: String.downcase(role_name))
  end

  @doc """
    Returns role of user in a data domain
  """
  def get_role_in_resource(%{user_id: principal_id, data_domain_id: resource_id}) do
    data_domain = Taxonomies.get_data_domain!(resource_id)
    data_domain = data_domain |> Repo.preload(:domain_group)
    role_name = get_resource_role(%{user_id: principal_id, data_domain: data_domain})
    %Role{name: role_name}
  end

  @doc """
    Returns role of user in domain_group
  """
  def get_role_in_resource(%{user_id: principal_id, domain_group_id: resource_id}) do
    domain_group = Taxonomies.get_domain_group(resource_id)
    domain_group = domain_group |> Repo.preload(:parent)
    role_name = get_resource_role(%{user_id: principal_id, domain_group: domain_group, role: nil})
    %Role{name: role_name}
  end

  defp get_resource_role(%{user_id: _principal_id, data_domain: %DataDomain{domain_group_id: nil}, role: nil} = attrs) do
    case get_role_by_principal_and_resource(attrs) do
      nil ->
        get_default_role()
      %Role{name: name} ->
        name
    end
  end

  defp get_resource_role(%{user_id: _principal_id, data_domain: %DataDomain{domain_group_id: nil}, role: role} = attrs) do
    case get_role_by_principal_and_resource(attrs) do
      nil ->
        role.name
      %Role{name: name} ->
        name
    end
  end

  defp get_resource_role(%{user_id: principal_id, data_domain: %DataDomain{} = data_domain} = attrs) do
    role = get_role_by_principal_and_resource(attrs)
    parent_domain_group = Taxonomies.get_domain_group(data_domain.domain_group_id)
    parent_domain_group = parent_domain_group |> Repo.preload(:parent)
    get_resource_role(%{user_id: principal_id, domain_group: parent_domain_group, role: role})
  end

  defp get_resource_role(%{user_id: _principal_id, domain_group: %DomainGroup{parent_id: nil}, role: nil} = attrs) do
    case get_role_by_principal_and_resource(attrs) do
      nil ->
        get_default_role()
      %Role{name: name} ->
        name
    end
  end

  defp get_resource_role(%{user_id: _principal_id, domain_group: %DomainGroup{parent_id: nil}, role: role} = attrs) do
    case get_role_by_principal_and_resource(attrs) do
      nil ->
        role.name
      %Role{name: name} ->
        name
    end
  end

  defp get_resource_role(%{user_id: principal_id, domain_group: %DomainGroup{} = domain_group, role: nil} = attrs) do
    role = get_role_by_principal_and_resource(attrs)
    parent_domain_group = Taxonomies.get_domain_group(domain_group.parent_id)
    parent_domain_group = parent_domain_group |> Repo.preload(:parent)
    get_resource_role(%{user_id: principal_id, role: role, domain_group: parent_domain_group})
  end

  defp get_resource_role(%{user_id: _principal_id, domain_group: %DomainGroup{} = _domain_group, role: role}) do
    role.name
  end

  def get_default_role do
    Role.watch |> Atom.to_string
  end

  defp get_role_by_principal_and_resource(%{user_id: _principal_id, domain_group: %DomainGroup{}} = attrs) do
    acl_entry =
      case get_acl_entry_by_principal_and_resource(attrs) do
        nil ->  nil
        acl_entry -> acl_entry |> Repo.preload(:role)
      end
    case acl_entry do
      nil -> nil
      acl_entry -> acl_entry.role
    end
  end

  defp get_role_by_principal_and_resource(%{user_id: _principal_id, data_domain: %DataDomain{}} = attrs) do
    acl_entry =
      case get_acl_entry_by_principal_and_resource(attrs) do
        nil ->  nil
        acl_entry -> acl_entry |> Repo.preload(:role)
      end
    case acl_entry do
      nil -> nil
      acl_entry -> acl_entry.role
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
end
