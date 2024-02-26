defmodule TdBg.I18nContents.I18nContent do
  @moduledoc """
  Ecto Schema module for I18n Content
  """

  use Ecto.Schema
  alias TdBg.BusinessConcepts.BusinessConceptVersion

  import Ecto.Changeset

  schema "i18n_contents" do
    field(:lang, :string)
    field(:name, :string)
    field(:content, :map)
    belongs_to(:business_concept_version, BusinessConceptVersion)

    timestamps(type: :utc_datetime_usec)
  end

  def changeset(params), do: changeset(%__MODULE__{}, params)

  def changeset(%__MODULE__{} = schema, %{} = params) do
    schema
    |> cast(params, [:lang, :name, :content, :business_concept_version_id])
    |> validate_required([:lang, :name, :content, :business_concept_version_id])
    |> validate_length(:name, max: 255)
    |> unique_constraint([:business_concept_version_id, :lang])
  end
end
