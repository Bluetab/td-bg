defmodule TrueBG.Taxonomies do
  @moduledoc """
  The Taxonomies context.
  """

  import Ecto.Query, warn: false
  alias Ecto.NoResultsError
  alias Ecto.MultipleResultsError
  alias TrueBG.Repo
  alias TrueBG.Taxonomies.DataDomain
  alias TrueBG.Taxonomies.DomainGroup
  alias TrueBG.Permissions.AclEntry
  alias Ecto.Multi

  @doc """
  Returns the list of domain_groups.

  ## Examples

      iex> list_domain_groups()
      [%DomainGroup{}, ...]

  """
  def list_domain_groups do
    Repo.all from r in DomainGroup, where: is_nil(r.deleted_at)
  end

  @doc """
  Returns the list of root domain_groups (no parent)
  """
  def list_root_domain_groups do
    Repo.all from r in DomainGroup, where: is_nil(r.parent_id) and is_nil(r.deleted_at)
  end

  @doc """
  Returns children of domain group id passed as argument
  """
  def count_domain_group_children(id) do
    count = Repo.one from r in DomainGroup, select: count(r.id), where: r.parent_id == ^id and is_nil(r.deleted_at)
    {:ok, count}
  end

  @doc """
  Returns children of domain group id passed as argument
  """
  def list_domain_group_children(id) do
    Repo.all from r in DomainGroup, where: r.parent_id == ^id and is_nil(r.deleted_at)
  end

  @doc """
  """
  def list_children_data_domain(domain_group_id) do
    query = from dd in DataDomain,
            where: dd.domain_group_id == ^domain_group_id
    Repo.all(query)
  end

  @doc """
  Gets a single domain_group.

  Raises `Ecto.NoResultsError` if the Domain group does not exist.

  ## Examples

      iex> get_domain_group!(123)
      %DomainGroup{}

      iex> get_domain_group!(456)
      ** (Ecto.NoResultsError)

  """
  def get_domain_group!(id) do
    all = Repo.all from r in DomainGroup, where: r.id == ^id and is_nil(r.deleted_at)
    one!(all, DomainGroup)
  end

  def get_domain_group(id) do
    all = Repo.all from r in DomainGroup, where: r.id == ^id and is_nil(r.deleted_at)
    one(all, DomainGroup)
  end

  def get_domain_group_by_name(name) do
    all = Repo.all from r in DomainGroup, where: r.name == ^name and is_nil(r.deleted_at)
    one(all, DomainGroup)
  end

  @doc """
  Creates a domain_group.

  ## Examples

      iex> create_domain_group(%{field: value})
      {:ok, %DomainGroup{}}

      iex> create_domain_group(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_domain_group(attrs \\ %{}) do
    %DomainGroup{}
    |> DomainGroup.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a domain_group.

  ## Examples

      iex> update_domain_group(domain_group, %{field: new_value})
      {:ok, %DomainGroup{}}

      iex> update_domain_group(domain_group, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_domain_group(%DomainGroup{} = domain_group, attrs) do
    domain_group
    |> DomainGroup.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a DomainGroup.

  ## Examples

      iex> delete_domain_group(domain_group)
      {:ok, %DomainGroup{}}

      iex> delete_domain_group(domain_group)
      {:error, %Ecto.Changeset{}}

  """
  def delete_domain_group(%DomainGroup{} = domain_group) do
    Multi.new
    |> Multi.delete_all(:acl_entry, from(acl in AclEntry, where: acl.resource_type == "domain_group" and acl.resource_id == ^domain_group.id))
    |> Multi.update(:domain_group, DomainGroup.delete_changeset(domain_group))
    |> Repo.transaction
    |> case do
      {:ok, %{acl_entry: _acl_entry, domain_group: domain_group}} ->
        {:ok, domain_group}
     end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking domain_group changes.

  ## Examples

      iex> change_domain_group(domain_group)
      %Ecto.Changeset{source: %DomainGroup{}}

  """
  def change_domain_group(%DomainGroup{} = domain_group) do
    DomainGroup.changeset(domain_group, %{})
  end

  @doc """

  """
  def get_parent_id(nil) do
    {:error, nil}
  end
  def get_parent_id(%{"parent_id": nil}) do
    {:ok, nil}
  end
  def get_parent_id(%{"parent_id": parent_id}) do
    get_parent_id(get_domain_group(parent_id))
  end
  def get_parent_id(parent_id) do
    {:ok, parent_id}
  end

  @doc """
  Returns the list of data_domains.

  ## Examples

      iex> list_data_domains()
      [%DataDomain{}, ...]

  """
  def list_data_domains do
    Repo.all(DataDomain)
  end

  def get_data_domain_by_name(name) do
    Repo.get_by(DataDomain, name: name)
  end

  @doc """
  Gets a single data_domain.

  Raises `Ecto.NoResultsError` if the Data domain does not exist.

  ## Examples

      iex> get_data_domain!(123)
      %DataDomain{}

      iex> get_data_domain!(456)
      ** (Ecto.NoResultsError)

  """
  def get_data_domain!(id), do: Repo.get!(DataDomain, id)

  @doc """
  Creates a data_domain.

  ## Examples

      iex> create_data_domain(%{field: value})
      {:ok, %DataDomain{}}

      iex> create_data_domain(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_data_domain(attrs \\ %{}) do
    %DataDomain{}
    |> DataDomain.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a data_domain.

  ## Examples

      iex> update_data_domain(data_domain, %{field: new_value})
      {:ok, %DataDomain{}}

      iex> update_data_domain(data_domain, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_data_domain(%DataDomain{} = data_domain, attrs) do
    data_domain
    |> DataDomain.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a DataDomain.

  ## Examples

      iex> delete_data_domain(data_domain)
      {:ok, %DataDomain{}}

      iex> delete_data_domain(data_domain)
      {:error, %Ecto.Changeset{}}

  """
  def delete_data_domain(%DataDomain{} = data_domain) do
    Multi.new
    |> Multi.delete_all(:acl_entry, from(acl in AclEntry, where: acl.resource_type == "data_domain" and acl.resource_id == ^data_domain.id))
    |> Multi.delete(:data_domain, data_domain)
    |> Repo.transaction
    |> case do
         {:ok, %{acl_entry: _acl_entry, data_domain: data_domain}} ->
           {:ok, data_domain}
       end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking data_domain changes.

  ## Examples

      iex> change_data_domain(data_domain)
      %Ecto.Changeset{source: %DataDomain{}}

  """
  def change_data_domain(%DataDomain{} = data_domain) do
    DataDomain.changeset(data_domain, %{})
  end

  defp one!(all, queryable) do
    case all do
      [one] -> one
      []    -> raise NoResultsError, queryable: queryable
      other -> raise MultipleResultsError, queryable: queryable, count: length(other)
    end

  end

  defp one(all, queryable) do
    case all do
      [one] -> one
      []    -> nil
      other -> raise MultipleResultsError, queryable: queryable, count: length(other)
    end
  end

end
