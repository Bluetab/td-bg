defmodule TrueBG.Taxonomies.BusinessConcept do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset
  alias TrueBG.Taxonomies.DataDomain
  alias TrueBG.Taxonomies.BusinessConcept

  @status [:draft]

  schema "business_concepts" do
    field :content, :map
    field :type, :string
    field :name, :string
    field :description, :string
    field :modifier, :integer
    field :last_change, :utc_datetime
    belongs_to :data_domain, DataDomain
    field :status, :string
    field :version, :integer

    timestamps()
  end

  @doc false
  def changeset(%BusinessConcept{} = business_concept, attrs) do
    business_concept
    |> cast(attrs, [:content, :type, :name, :description, :modifier,
                    :last_change, :data_domain_id, :status, :version])
    |> validate_required([:content, :type, :name, :modifier, :last_change,
                          :data_domain_id, :status, :version])
    |> validate_length(:name, max: 255)
    |> validate_length(:description, max: 500)
  end

  def get_status do
    @status
  end

  def draft do
    :draft
  end

end
