defmodule TdBg.Permissions.Role do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset
  alias TdBg.Permissions.Role
  alias TdBg.Permissions.Permission

  schema "roles" do
    field :name, :string
    many_to_many :permissions, Permission, join_through: "roles_permissions", on_replace: :delete, on_delete: :delete_all

    timestamps()
  end

  @doc false
  def changeset(%Role{} = role, attrs) do
    role
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end

end
