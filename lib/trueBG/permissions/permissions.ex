defmodule TrueBG.Permissions do
  @moduledoc """
  The Permissions context.
  """

  import Ecto.Query, warn: false
  alias TrueBG.Repo

  alias TrueBG.Permissions.AclEntry

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
end
