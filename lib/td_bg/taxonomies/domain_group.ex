defmodule TdBg.Taxonomies.DomainGroup do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset
  alias TdBg.Taxonomies.DomainGroup
  alias TdBg.Searchable

  @behaviour Searchable

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

  def search_fields(%DomainGroup{} = domain_group) do
    %{name: domain_group.name, description: domain_group.description, parent_id: domain_group.parent_id}
  end

  def index_name do
    "domain_group"
  end

end
