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
    Returns a list of users-role with acl_entries in the domain_group passed as argument
  """
  def list_acl_entries(%{domain_group: domain_group}) do
    acl_entries = Repo.all(from acl_entry in AclEntry, where: acl_entry.resource_type == "domain_group" and acl_entry.resource_id == ^domain_group.id)
    acl_entries |> Repo.preload(:role)
  end

  @doc """

  """
  def list_acl_entries_by_principal(%{principal_id: principal_id, principal_type: principal_type}) do
    acl_entries = Repo.all(from acl_entry in AclEntry, where: acl_entry.principal_type == ^principal_type and acl_entry.principal_id == ^principal_id)
    acl_entries |> Repo.preload(:role)
  end

  @doc """

  """
  def get_acl_entry_by_principal_and_resource(%{user_id: principal_id, resource_type: resource_type, resource_id: resource_id}) do
    Repo.get_by(AclEntry, principal_type: "user", principal_id: principal_id, resource_type: resource_type, resource_id: resource_id)
  end

  @doc """
    Returns acl entry for an user and domain group
  """
  def get_acl_entry_by_principal_and_resource(%{user_id: principal_id, domain_group: domain_group}) do
    Repo.get_by(AclEntry, principal_type: "user", principal_id: principal_id, resource_type: "domain_group", resource_id: domain_group.id)
  end

  @doc """
    Returns acl entry for an user and data domain
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
    case get_role_by_principal_and_resource(attrs) do
      nil ->
        parent_domain_group = Taxonomies.get_domain_group(data_domain.domain_group_id)
        parent_domain_group = parent_domain_group |> Repo.preload(:parent)
        get_resource_role(%{user_id: principal_id, domain_group: parent_domain_group, role: nil})
      %Role{name: name} ->
        name
    end
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

  @doc """
    Returns flat list of DG and DDs user roles
  """
  def assemble_roles(%{user_id: user_id}) do
    tree = Taxonomies.tree()
    all_acls = list_acl_entries_by_principal(%{principal_id: user_id, principal_type: "user"})
    all_dgs = Taxonomies.list_domain_groups()
    all_dds = Taxonomies.list_data_domains()
    roles = []
    roles = Enum.reduce(tree, roles, fn(node, acc) ->
      branch_roles = assemble_node_role(node, user_id, all_acls, roles, all_dgs, all_dds)
      Enum.uniq(List.flatten(acc ++ branch_roles))
    end)
    roles
  end

  defp build_dg_map(%{"id": id, "role": role, "acl_entry_id": acl_entry_id, "inherited": inherited}) do
    %{"id": id, "type": "DG", "role": role, "acl_entry_id": acl_entry_id, "inherited": inherited}
  end

  defp build_dd_map(%{"id": id, "role": role, "acl_entry_id": acl_entry_id, "inherited": inherited}) do
    %{"id": id, "type": "DD", "role": role, "acl_entry_id": acl_entry_id, "inherited": inherited}
  end

  defp assemble_node_role(%DomainGroup{parent_id: nil} = dg, user_id, all_acls, roles, all_dgs, all_dds) do
    custom_role = get_role_in_resource(%{user_id: user_id, domain_group_id: dg.id})
    custom_acl = Enum.find(all_acls, fn(acl) -> acl.resource_type == "domain_group" && acl.resource_id == dg.id end)
    custom_acl_id = if custom_acl do
      custom_acl.id
    else
      nil
    end
    roles = roles ++ [build_dg_map(%{id: dg.id, role: custom_role.name, acl_entry_id: custom_acl_id, inherited: custom_acl == nil})]
    Enum.reduce(dg.children, roles, fn(child_dg, acc) ->
      Enum.uniq(List.flatten(acc ++ [assemble_node_role(child_dg, user_id, all_acls, roles, all_dgs, all_dds)]))
    end)
  end

  defp assemble_node_role(%DomainGroup{} = dg, user_id, all_acls, roles, all_dgs, all_dds) do
    custom_acl = Enum.find(all_acls, fn(acl) -> acl.resource_type == "domain_group" && acl.resource_id == dg.id end)
    roles = if custom_acl do
      roles ++ [build_dg_map(%{id: dg.id, role: custom_acl.role.name, acl_entry_id: custom_acl.id, inherited: false})]
    else
      roles ++ [get_closest_role(dg, roles, all_dgs, all_dds)]
    end
    Enum.reduce(dg.children, roles, fn(child_dg, acc) ->
      Enum.uniq(List.flatten(acc ++ [assemble_node_role(child_dg, user_id, all_acls, roles, all_dgs, all_dds)]))
    end)
  end

  defp assemble_node_role(%DataDomain{} = dd, _user_id, all_acls, roles, all_dgs, all_dds) do
    custom_acl = Enum.find(all_acls, fn(acl) -> acl.resource_type == "data_domain" && acl.resource_id == dd.id end)
    if custom_acl do
      build_dd_map(%{id: dd.id, role: custom_acl.role.name, acl_entry_id: custom_acl.id, inherited: false})
    else
      get_closest_role(dd, roles, all_dgs, all_dds)
    end
  end

  defp get_closest_role(%DomainGroup{} = dg, roles, all_dgs, all_dds) do
    role = Enum.find(roles, fn(role) -> role.id == dg.parent_id && role.type == "DG" end)
    if role do
      build_dg_map(%{id: dg.id, role: role.role, acl_entry_id: nil, inherited: true})
    else
      parent_dg = Enum.find(all_dgs, fn(i_dg) -> i_dg.id == dg.parent_id end)
      get_closest_role(parent_dg, roles, all_dgs, all_dds)
    end
  end

  defp get_closest_role(%DataDomain{} = dd, roles, all_dgs, all_dds) do
    role = Enum.find(roles, fn(role) -> role.id == dd.domain_group_id && role.type == "DG" end)
    if role do
      build_dd_map(%{id: dd.id, role: role.role, acl_entry_id: nil, inherited: true})
    else
      parent_dg = Enum.find(all_dgs, fn(i_dg) -> i_dg.id == dd.parent_id end)
      get_closest_role(parent_dg, roles, all_dgs, all_dds)
    end
  end
end
