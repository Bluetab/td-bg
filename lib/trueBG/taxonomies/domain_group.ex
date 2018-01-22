defmodule TrueBG.Taxonomies.DomainGroup do
  use Ecto.Schema
  import Ecto.Changeset
  alias TrueBG.Taxonomies.DomainGroup


  schema "domain_groups" do
    field :description, :string
    field :name, :string
    has_one :parent, DomainGroup

    timestamps()
  end

  @doc false
  def changeset(%DomainGroup{} = domain_group, attrs) do
    domain_group
    |> cast(attrs, [:name, :description])
    |> validate_required([:name, :description])
  end
end
