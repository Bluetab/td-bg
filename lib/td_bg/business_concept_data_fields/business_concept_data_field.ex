defmodule TdBg.BusinessConceptDataFields.BusinessConceptDataField do
  @moduledoc false
  use Ecto.Schema

  import Ecto.Changeset

  alias TdBg.BusinessConceptDataFields.BusinessConceptDataField

  schema "business_concept_data_fields" do
    field :business_concept, :string
    field :data_field, :string

    timestamps()
  end

  @doc false
  def changeset(%BusinessConceptDataField{} = business_concept_data_field, attrs) do
    business_concept_data_field
    |> cast(attrs, [:business_concept, :data_field])
    |> validate_required([:business_concept, :data_field])
  end

end
