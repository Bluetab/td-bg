defmodule TrueBG.Taxonomies do
  @moduledoc """
  The Taxonomies context.
  """

  import Ecto.Query, warn: false
  alias TrueBG.Repo
  alias TrueBG.Taxonomies.DataDomain
  alias TrueBG.Taxonomies.DomainGroup

  @doc """
  Returns the list of domain_groups.

  ## Examples

      iex> list_domain_groups()
      [%DomainGroup{}, ...]

  """
  def list_domain_groups do
    Repo.all(DomainGroup)
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
  def get_domain_group!(id), do: Repo.get!(DomainGroup, id)

  def get_domain_group(id), do: Repo.get(DomainGroup, id)

  def get_domain_group_by_name(name) do
    Repo.get_by(DomainGroup, name: String.downcase(name))
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
    Repo.delete(domain_group)
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
    Repo.delete(data_domain)
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
end
