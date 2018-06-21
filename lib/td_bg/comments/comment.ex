defmodule TdBg.Comments.Comment do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset

  schema "comments" do
    field :content, :string
    field :resource_id, :integer
    field :resource_type, :string
    field :user, :map
    field :created_at, :utc_datetime

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:content, :resource_id, :resource_type, :user, :created_at])
    |> validate_required([:content, :resource_id, :resource_type, :user, :created_at])
  end
end
