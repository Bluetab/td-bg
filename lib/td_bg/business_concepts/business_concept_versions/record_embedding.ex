defmodule TdBg.BusinessConcepts.BusinessConceptVersions.RecordEmbedding do
  @moduledoc """
  Stores business concept version embeddings
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias TdBg.BusinessConcepts.BusinessConceptVersion
  alias Timer

  @derive Jason.Encoder
  schema "record_embeddings" do
    field(:collection, :string)
    field(:dims, :integer)
    field(:embedding, {:array, :float})

    belongs_to(:business_concept_version, BusinessConceptVersion, on_replace: :update)

    timestamps(type: :utc_datetime_usec)
  end

  @doc false
  def changeset(record_embedding, attrs) do
    record_embedding
    |> cast(attrs, [:business_concept_version_id, :collection, :dims, :embedding])
    |> validate_required([:business_concept_version_id, :collection, :dims, :embedding])
  end

  def coerce(%{"id" => id, "inserted_at" => inserted_at, "updated_at" => updated_at} = attrs) do
    inserted_at = Timer.binary_to_utc_date_time(inserted_at)
    updated_at = Timer.binary_to_utc_date_time(updated_at)

    %__MODULE__{}
    |> changeset(attrs)
    |> apply_changes()
    |> Map.put(:id, id)
    |> Map.put(:inserted_at, inserted_at)
    |> Map.put(:updated_at, updated_at)
  end
end
