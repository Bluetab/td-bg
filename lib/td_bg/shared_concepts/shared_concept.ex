defmodule TdBg.SharedConcepts.SharedConcept do
  @moduledoc """
  Relation between a business concept and its 
  """
  use Ecto.Schema

  alias TdBg.BusinessConcepts.BusinessConcept
  alias TdBg.Taxonomies.Domain

  schema "shared_concepts" do
    belongs_to(:domain, Domain)
    belongs_to(:business_concept, BusinessConcept)

    timestamps(type: :utc_datetime_usec, updated_at: false)
  end
end
