defmodule TrueBG.Permissions do
  @moduledoc """
  The Permissions context.
  """

  import Ecto.Query, warn: false
  alias TrueBG.Repo

  alias TrueBG.Permissions.AclEntry
  alias TrueBG.Permissions.Role
  alias TrueBG.Accounts
  alias TrueBG.Accounts.User
  alias TrueBG.Taxonomies.DataDomain
  alias TrueBG.Taxonomies.DomainGroup
  alias TrueBG.Taxonomies

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

  """
  def get_acl_entry_by_principal_and_resource(:user, user_id, :domain_group, resource_id) do
    Repo.get_by(AclEntry, principal_type: "user", principal_id: user_id, resource_type: "domain_group", resource_id: resource_id)
  end

  @doc """

  """
  def get_acl_entry_by_principal_and_resource(:user, user_id, :data_domain, resource_id) do
    Repo.get_by(AclEntry, principal_type: "user", principal_id: user_id, resource_type: "data_domain", resource_id: resource_id)
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
    Inserts a Role record in Role schema
  """
  def create_role(attrs) do
    %Role{}
    |> Role.changeset(attrs)
    |> Repo.insert()
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
  def get_role_in_resource(:user, principal_id, :data_domain, resource_id) do
    data_domain = Taxonomies.get_data_domain!(resource_id)
    data_domain = data_domain |> Repo.preload(:domain_group)
    user = Accounts.get_user!(principal_id)
    get_resource_role(user, data_domain, nil)
  end

  @doc """
    Returns role of user in domain_group
  """
  def get_role_in_resource(:user, principal_id, :domain_group, resource_id) do
    domain_group = Taxonomies.get_domain_group(resource_id)
    domain_group = domain_group |> Repo.preload(:parent)
    user = Accounts.get_user!(principal_id)
    get_resource_role(user, domain_group, nil)
  end

  defp get_resource_role(%User{} = user, %DataDomain{domain_group_id: nil} = data_domain, role) do
    case get_role_by_principal_and_resource(:user, user.id, :data_domain, data_domain.id) do
      nil ->
        if role do
          role.name
        else
          get_default_role()
        end
      %Role{name: name} -> name
      _ -> :error
    end
  end

  defp get_resource_role(%User{} = user, %DataDomain{} = data_domain, _role) do
    role = get_role_by_principal_and_resource(:user, user.id, :data_domain, data_domain.id)
    parent_domain_group = Taxonomies.get_domain_group(data_domain.domain_group.id)
    parent_domain_group = parent_domain_group |> Repo.preload(:parent)
    get_resource_role(user, parent_domain_group, role)
  end

  defp get_resource_role(%User{} = user, %DomainGroup{parent_id: nil} = domain_group, role) do
    case get_role_by_principal_and_resource(:user, user.id, :domain_group, domain_group.id) do
      nil ->
        if role do
          role.name
        else
          get_default_role()
        end
      %Role{name: name} -> name
      _ -> :error
    end
  end

  defp get_resource_role(%User{} = user, %DomainGroup{} = domain_group, nil) do
    role = get_role_by_principal_and_resource(:user, user.id, :domain_group, domain_group.id)
    parent_domain_group = Taxonomies.get_domain_group(domain_group.parent.id)
    parent_domain_group = parent_domain_group |> Repo.preload(:parent)
    get_resource_role(user, parent_domain_group, role)
  end

  defp get_resource_role(%User{} = _user, %DomainGroup{} = _domain_group, role) do
    role.name
  end

  def get_default_role do
    Role.watch |> Atom.to_string
  end

  defp get_role_by_principal_and_resource(:user, principal_id, :domain_group, resource_id) do
    acl_entry =
      case get_acl_entry_by_principal_and_resource(:user, principal_id, :domain_group, resource_id) do
        nil ->  nil
        acl_entry -> acl_entry |> Repo.preload(:role)
      end
    case acl_entry do
      nil -> nil
      acl_entry -> acl_entry.role
    end
  end

  defp get_role_by_principal_and_resource(:user, principal_id, :data_domain, resource_id) do
    acl_entry =
      case get_acl_entry_by_principal_and_resource(:user, principal_id, :data_domain, resource_id) do
        nil ->  nil
        acl_entry -> acl_entry |> Repo.preload(:role)
      end
    case acl_entry do
      nil -> nil
      acl_entry -> acl_entry.role
    end
  end

end
