defmodule TrueBG.Taxonomies.DomainGroup do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset
  alias TrueBG.Taxonomies.DomainGroup

  schema "domain_groups" do
    field :description, :string
    field :name, :string
    belongs_to :parent, DomainGroup
    timestamps()
  end

  @doc false
  def changeset(%DomainGroup{} = domain_group, attrs) do
    domain_group
      |> cast(attrs, [:name, :description, :parent_id])
      |> validate_required([:name])
      |> unique_constraint(:name)
  end
end
