defmodule TrueBG.Taxonomies.DomainGroup do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset
  alias TrueBG.Taxonomies.DomainGroup

  schema "domain_groups" do
    field :description, :string
    field :name, :string
    belongs_to :parent, DomainGroup
    field :deleted_at, :utc_datetime, default: nil

    timestamps()
  end

  @doc false
  def changeset(%DomainGroup{} = domain_group, attrs) do
    domain_group
      |> cast(attrs, [:name, :description, :parent_id])
      |> validate_required([:name])
      |> unique_constraint(:name)
  end

  @doc false
  def delete_changeset(%DomainGroup{} = domain_group) do
    domain_group
    |> cast(%{}, [])
    |> put_change(:deleted_at, DateTime.utc_now())
  end

end
