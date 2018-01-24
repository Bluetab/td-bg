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

    timestamps()
  end

  @doc false
  def changeset(%DataDomain{} = data_domain, attrs) do
    data_domain
    |> cast(attrs, [:name, :description, :domain_group_id])
    |> validate_required([:name, :description])
  end
end
