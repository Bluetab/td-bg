defmodule TrueBG.Permissions.Role do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset
  alias TrueBG.Permissions.Role

  @roles [:admin, :watch, :create, :publish]

  schema "roles" do
    field :name, :string

    timestamps()
  end

  @doc false
  def changeset(%Role{} = role, attrs) do
    role
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end

  def get_roles do
    @roles
  end

  def admin do
    :admin
  end

  def watch do
    :watch
  end

end
