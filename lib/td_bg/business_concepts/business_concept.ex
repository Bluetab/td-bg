defmodule TdBg.BusinessConcepts.BusinessConcept do
  @moduledoc """
  Ecto Schema module for Business Concepts.
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias TdBg.BusinessConcepts.BusinessConceptVersion
  alias TdBg.Taxonomies.Domain

  schema "business_concepts" do
    belongs_to(:domain, Domain)
    field(:type, :string)
    field(:last_change_by, :integer)
    field(:last_change_at, :utc_datetime_usec)

    has_many(:versions, BusinessConceptVersion)

    timestamps(type: :utc_datetime_usec)
  end

  def changeset(%__MODULE__{} = business_concept, attrs) do
    business_concept
    |> cast(attrs, [:domain_id, :type, :last_change_by, :last_change_at])
    |> validate_required([:domain_id, :type, :last_change_by, :last_change_at])
  end
end
