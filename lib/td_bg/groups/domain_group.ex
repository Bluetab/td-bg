defmodule TdBg.Groups.DomainGroup do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset

  schema "domain_groups" do
    field(:name, :string)

    timestamps()
  end

  @doc false
  def changeset(domain_group, attrs) do
    domain_group
    |> cast(attrs, [:name])
    |> validate_required([:name])
    |> unique_constraint(:name, [name: :index_domain_group_name])
  end
end
