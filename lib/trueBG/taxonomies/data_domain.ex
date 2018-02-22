defmodule TrueBG.Taxonomies.DataDomain do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset
  alias TrueBG.Taxonomies.DataDomain
  alias TrueBG.Taxonomies.DomainGroup

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
      |> unique_constraint(:domain_group, name: :data_domains_name_domain_group_id_index)
  end

  @doc false
  def delete_changeset(%DataDomain{} = data_domain) do
    data_domain
    |> cast(%{}, [])
    |> put_change(:deleted_at, DateTime.utc_now())
  end

end
