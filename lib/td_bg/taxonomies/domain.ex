defmodule TdBg.Taxonomies.Domain do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset
  alias TdBg.Taxonomies.Domain
  alias TdBg.Searchable

  @behaviour Searchable

  schema "domains" do
    field :description, :string
    field :name, :string
    belongs_to :parent, Domain

    timestamps()
  end

  @doc false
  def changeset(%Domain{} = domain, attrs) do
    domain
      |> cast(attrs, [:name, :description, :parent_id])
      |> validate_required([:name])
      |> unique_constraint(:name)
      # Just in case
      #|> unique_constraint(:name, name: :data_domains_name_domain_group_id_index)
  end

  @doc false
  def delete_changeset(%Domain{} = domain) do
    domain
    |> cast(%{}, [])
  end

  def search_fields(%Domain{} = domain) do
    %{name: domain.name, description: domain.description, parent_id: domain.parent_id}
  end

  def index_name do
    "domain"
  end

end
