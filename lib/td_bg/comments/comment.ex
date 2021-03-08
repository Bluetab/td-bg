defmodule TdBg.Comments.Comment do
  @moduledoc """
  Ecto Schema module for comments.
  """

  use Ecto.Schema

  import Ecto.Changeset

  schema "comments" do
    field(:content, :string)
    field(:resource_id, :integer)
    field(:resource_type, :string)
    field(:user, :map)
    field(:domain_ids, {:array, :integer}, virtual: true)
    field(:subscribable_fields, {:array, :string}, virtual: true)
    field(:version_id, :integer, virtual: true)
    field(:resource_name, :string, virtual: true)

    timestamps(type: :utc_datetime_usec, updated_at: false)
  end

  def changeset(%{} = params) do
    changeset(%__MODULE__{}, params)
  end

  def changeset(%__MODULE__{} = struct, %{} = params) do
    struct
    |> cast(params, [:content, :resource_id, :resource_type, :user])
    |> validate_required([:content, :resource_id, :resource_type, :user])
  end
end
