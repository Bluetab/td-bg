defmodule TdBg.ConceptFields.ConceptField do
  @moduledoc false
  use Ecto.Schema

  import Ecto.Changeset

  alias TdBg.ConceptFields.ConceptField

  schema "concept_fields" do
    field :concept, :string
    field :field, :string

    timestamps()
  end

  @doc false
  def changeset(%ConceptField{} = concept_field, attrs) do
    concept_field
    |> cast(attrs, [:concept, :field])
    |> validate_required([:concept, :field])
  end

end
