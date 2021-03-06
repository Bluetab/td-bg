defmodule TdBg.Groups do
  @moduledoc """
  The Groups context.
  """

  import Ecto.Query, warn: false
  alias TdBg.Repo

  alias TdBg.Groups.DomainGroup

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

  @doc """
  Gets a single domain_group.

  ## Examples

      iex> get_domain_group!(123)
      %DomainGroup{}

      iex> get_domain_group!(456)
      ** nil

  """
  def get_domain_group(id), do: Repo.get(DomainGroup, id)

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
  Deletes a domain_group.

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
      %Ecto.Changeset{data: %DomainGroup{}}

  """
  def change_domain_group(%DomainGroup{} = domain_group, attrs \\ %{}) do
    DomainGroup.changeset(domain_group, attrs)
  end

  @doc """
  Fetches a single domain group matching the specified clauses.
  See `Repo.get_by/2`.

  ## Examples

      iex> get_by(name: name)
      %DomainGroup{}

      iex> get_by(name: name)
      nil

  """
  def get_by(clauses) do
    Repo.get_by(DomainGroup, clauses)
  end
end
