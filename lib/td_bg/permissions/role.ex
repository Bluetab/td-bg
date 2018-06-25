defmodule TdBg.Permissions.Role do
  @moduledoc false

  use Ecto.Schema
  alias Ecto.Changeset
  alias TdBg.Permissions.Permission
  alias TdBg.Permissions.Role
  alias TdBg.Repo

  schema "roles" do
    field(:name, :string)

    many_to_many(
      :permissions,
      Permission,
      join_through: "roles_permissions",
      on_replace: :delete,
      on_delete: :delete_all
    )

    timestamps()
  end

  @doc false
  def changeset(%Role{} = role, attrs) do
    role
    |> Changeset.cast(attrs, [:name])
    |> Changeset.validate_required([:name])
  end

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
    |> changeset(attrs)
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
    |> changeset(attrs)
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
    Returns Role with name role_name
  """
  def get_role_by_name(role_name) do
    Repo.get_by(Role, name: role_name)
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

end
