defmodule TdBg.BusinessConcepts.BusinessConceptAlias do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset
  alias TdBg.BusinessConcepts.BusinessConcept
  alias TdBg.BusinessConcepts.BusinessConceptAlias

  schema "business_concept_aliases" do
    field :name, :string
    belongs_to :business_concept, BusinessConcept

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(%BusinessConceptAlias{} = business_concept_alias, attrs) do
    business_concept_alias
    |> cast(attrs, [:name, :business_concept_id])
    |> validate_required([:name, :business_concept_id])
    |> validate_length(:name, max: 255)
  end
end
