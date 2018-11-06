defmodule TdBg.Taxonomies.Domain do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset
  alias TdBg.Searchable
  alias TdBg.Taxonomies.Domain
  alias TdPerms.TaxonomyCache

  @behaviour Searchable

  schema "domains" do
    field :description, :string
    field :type, :string
    field :name, :string
    belongs_to :parent, Domain

    timestamps()
  end

  @doc false
  def changeset(%Domain{} = domain, attrs) do
    domain
      |> cast(attrs, [:name, :type, :description, :parent_id])
      |> validate_required([:name])
      |> unique_constraint(:name, name: :index_domain_by_name)
  end

  @doc false
  def delete_changeset(%Domain{} = domain) do
    domain
    |> cast(%{}, [])
  end

  def search_fields(%Domain{id: domain_id} = domain) do
    parent_ids = TaxonomyCache.get_parent_ids(domain_id, false)
    %{name: domain.name, description: domain.description, parent_id: domain.parent_id, parent_ids: parent_ids}
  end

  def index_name do
    "domain"
  end

end
