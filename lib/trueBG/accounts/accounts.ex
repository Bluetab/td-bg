defmodule TrueBG.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false
  alias TrueBG.Repo

  alias TrueBG.Accounts.User

  @doc """
  Returns the list of users.

  ## Examples

      iex> list_users()
      [%User{}, ...]

  """
  def list_users do
    Repo.all(User)
  end

  @doc """
  Gets a single user.

  Raises `Ecto.NoResultsError` if the User does not exist.

  ## Examples

      iex> get_user!(123)
      %User{}

      iex> get_user!(456)
      ** (Ecto.NoResultsError)

  """
  def get_user!(id) do
    %User{id: id}
  end

  def get_user_by_name(user_name) do
    %User{id: trunc(:binary.decode_unsigned(user_name)/10000000000000000), user_name: user_name}
  end

  # def exist_user?(user_name) do
  #   Repo.one(from u in User, select: count(u.id), where: u.user_name == ^user_name) > 0
  # end

  @doc """
  Creates a user.

  ## Examples

      iex> create_user(%{field: value})
      {:ok, %User{}}

      iex> create_user(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_user(attrs \\ %{}) do
    user_name = Map.get(attrs, "user_name")
    {:ok, %User{id: trunc(:binary.decode_unsigned(user_name)/10000000000000000), user_name: user_name, is_admin: false}}
  end

  @doc """
  Updates a user.

  ## Examples

      iex> update_user(user, %{field: new_value})
      {:ok, %User{}}

      iex> update_user(user, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  # def update_user(%User{} = user, attrs) do
  #   user
  #   |> User.changeset(attrs)
  #   |> Repo.update()
  # end

  @doc """
  Deletes a User.

  ## Examples

      iex> delete_user(user)
      {:ok, %User{}}

      iex> delete_user(user)
      {:error, %Ecto.Changeset{}}

  """
  # def delete_user(%User{} = user) do
  #   Repo.delete(user)
  # end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user changes.

  ## Examples

      iex> change_user(user)
      %Ecto.Changeset{source: %User{}}

  """
  # def change_user(%User{} = user) do
  #   User.changeset(user, %{})
  # end
end
