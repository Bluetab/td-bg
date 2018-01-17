defmodule TrueBG.Accounts.User do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset
  alias TrueBG.Accounts.User
  alias Comeonin.Bcrypt

  schema "users" do
    field :password_hash, :string
    field :user_name, :string
    field :password, :string, virtual: true

    timestamps()
  end

  @doc false
  def changeset(%User{} = user, attrs) do
    user
    |> cast(attrs, [:user_name, :password])
    |> validate_required([:user_name, :password])
    |> put_pass_hash()
  end

  defp put_pass_hash(%Ecto.Changeset{valid?: true, changes: %{password: password}} = changeset) do
    change(changeset, password_hash: Bcrypt.hashpwsalt(password))
  end

  defp put_pass_hash(changeset), do: changeset

  # def registration_changeset(model, params \\ :empty) do
  #   model
  #   |> changeset(params)
  #   |> cast(params, ~w(password))
  #   # |> validate_length(:password, min: 6)
  #   |> unique_constraint(:user_name, message: "User name must be unique")
  #   |> put_password_hash
  # end
  #
  # defp put_password_hash(changeset) do
  #   case changeset do
  #     %Ecto.Changeset{valid?: true, changes: %{password: passwd}} ->
  #       put_change(changeset, :password_hash,
  #                  Comeonin.Bcrypt.hashpwsalt(passwd))
  #     _ ->
  #       changeset
  #   end
  # end

end
