defmodule TdBg.Taxonomies.DataDomain do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset
  alias TdBg.Taxonomies.DataDomain
  alias TdBg.Taxonomies.DomainGroup
  alias TdBg.Searchable

  @behaviour Searchable

  schema "data_domains" do
    field :description, :string
    field :name, :string
    belongs_to :domain_group, DomainGroup
    field :deleted_at, :utc_datetime

    timestamps()
  end

  @doc false
  def changeset(%DataDomain{} = data_domain, attrs) do
    data_domain
      |> cast(attrs, [:name, :description, :domain_group_id])
      |> validate_required([:name])
      |> unique_constraint(:name, name: :data_domains_name_domain_group_id_index)
  end

  @doc false
  def delete_changeset(%DataDomain{} = data_domain) do
    data_domain
    |> cast(%{}, [])
    |> put_change(:deleted_at, DateTime.utc_now())
  end

  def search_fields(%DataDomain{} = data_domain) do
    %{name: data_domain.name, description: data_domain.description, domain_group_id: data_domain.domain_group_id}
  end

  def index_name do
    "data_domain"
  end

end
