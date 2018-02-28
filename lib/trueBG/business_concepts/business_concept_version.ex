defmodule TrueBG.BusinessConcepts.BusinessConceptVersion do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset
  alias TrueBG.BusinessConcepts.BusinessConcept
  alias TrueBG.BusinessConcepts.BusinessConceptVersion

  schema "business_concept_versions" do
    field :content, :map
    field :description, :string
    field :last_change_at, :utc_datetime
    field :mod_comments, :string
    field :last_change_by, :integer
    field :name, :string
    field :reject_reason, :string
    field :status, :string
    field :version, :integer
    belongs_to :business_concept, BusinessConcept, on_replace: :update

    timestamps()
  end

  @doc false
  def create_changeset(%BusinessConceptVersion{} = business_concept_version, attrs) do
    business_concept_version
    |> cast(attrs, [:content, :name, :description, :last_change_by, :last_change_at, :version, :mod_comments])
    |> put_assoc(:business_concept, attrs.business_concept)
    |> validate_required([:content, :name, :last_change_by, :last_change_at, :version, :business_concept])
    |> put_change(:status, BusinessConcept.status.draft)
    |> validate_length(:name, max: 255)
    |> validate_length(:description,  max: 500)
    |> validate_length(:mod_comments, max: 500)
  end

  def update_changeset(%BusinessConceptVersion{} = business_concept_version, attrs) do
    business_concept_version
    |> cast(attrs, [:content, :name, :description, :last_change_by, :last_change_at])
    |> cast_assoc(:business_concept)
    |> validate_required([:content, :name, :last_change_by, :last_change_at])
    |> validate_length(:name, max: 255)
    |> validate_length(:description, max: 500)
  end

  @doc false
  def update_status_changeset(%BusinessConceptVersion{} = business_concept_version, attrs) do
    business_concept_version
    |> cast(attrs, [:status])
    |> validate_required([:status])
    |> validate_inclusion(:status, Map.values(BusinessConcept.status))
  end

  @doc false
  def reject_changeset(%BusinessConceptVersion{} = business_concept_version, attrs) do
    business_concept_version
    |> cast(attrs, [:reject_reason])
    |> validate_length(:reject_reason, max: 500)
    |> put_change(:status, BusinessConcept.status.rejected)
  end

  @doc false
  def changeset(%BusinessConceptVersion{} = business_concept_version, attrs) do
    business_concept_version
    |> cast(attrs, [:name, :description, :content, :last_change_by, :last_change_at, :status, :version, :reject_reason, :mod_comments])
    |> validate_required([:name, :description, :content, :last_change_by, :last_change_at, :status, :version, :reject_reason, :mod_comments])
  end
end
