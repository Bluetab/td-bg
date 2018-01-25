defmodule TrueBG.Permissions.AclEntry do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset
  alias TrueBG.Permissions.AclEntry
  alias TrueBG.Permissions.Role

  schema "acl_entries" do
    field :principal_id, :integer
    field :principal_type, :string
    field :resource_id, :integer
    field :resource_type, :string
    belongs_to :role, Role

    timestamps()
  end

  @doc false
  def changeset(%AclEntry{} = acl_entry, attrs) do
    acl_entry
    |> cast(attrs, [:principal_type, :principal_id, :resource_type, :resource_id, :role_id])
    |> validate_required([:principal_type, :principal_id, :resource_type, :resource_id])
  end
end
