defmodule TrueBG.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset
  alias TrueBG.Accounts.User


  schema "users" do
    field :password_hash, :string
    field :user_name, :string
    # field :password, :string, virtual: true

    timestamps()
  end

  @doc false
  def changeset(%User{} = user, attrs) do
    user
    |> cast(attrs, [:user_name, :password_hash])
    |> validate_required([:user_name, :password_hash])
  end

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
  #       put_change(changeset, :password_hash, Comeonin.Bcrypt.hashpwsalt(passwd))
  #     _ ->
  #       changeset
  #   end
  # end

end
