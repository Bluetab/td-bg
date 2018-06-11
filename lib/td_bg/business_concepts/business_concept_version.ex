defmodule TdBg.BusinessConcepts.BusinessConceptVersion do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset
  alias TdBg.BusinessConcepts
  alias TdBg.BusinessConcepts.BusinessConcept
  alias TdBg.BusinessConcepts.BusinessConceptVersion
  alias TdBg.Taxonomies
  alias TdBg.Searchable

  @behaviour Searchable

  schema "business_concept_versions" do
    field :content, :map
    field :related_to, {:array, :integer}
    field :description, :string
    field :last_change_at, :utc_datetime
    field :mod_comments, :string
    field :last_change_by, :integer
    field :name, :string
    field :reject_reason, :string
    field :status, :string
    field :current, :boolean, default: true
    field :version, :integer
    belongs_to :business_concept, BusinessConcept, on_replace: :update

    timestamps()
  end

  @doc false
  def create_changeset(%BusinessConceptVersion{} = business_concept_version, attrs) do
    business_concept_version
    |> cast(attrs, [:content, :related_to, :name, :description, :last_change_by, :last_change_at, :version, :mod_comments])
    |> put_assoc(:business_concept, attrs.business_concept)
    |> validate_required([:content, :related_to, :name, :last_change_by, :last_change_at, :version, :business_concept])
    |> put_change(:status, BusinessConcept.status.draft)
    |> validate_length(:name, max: 255)
    |> validate_length(:description,  max: 500)
    |> validate_length(:mod_comments, max: 500)
  end

  def update_changeset(%BusinessConceptVersion{} = business_concept_version, attrs) do
    business_concept_version
    |> cast(attrs, [:content, :related_to, :name, :description, :last_change_by, :last_change_at, :mod_comments])
    |> cast_assoc(:business_concept)
    |> put_change(:status, BusinessConcept.status.draft)
    |> validate_required([:content, :related_to, :name, :last_change_by, :last_change_at])
    |> validate_length(:name, max: 255)
    |> validate_length(:description, max: 500)
    |> validate_length(:mod_comments, max: 500)
  end

  @doc false
  def update_status_changeset(%BusinessConceptVersion{} = business_concept_version, attrs) do
    business_concept_version
    |> cast(attrs, [:status])
    |> validate_required([:status])
    |> validate_inclusion(:status, Map.values(BusinessConcept.status))
  end

  @doc false
  def not_anymore_current_changeset(%BusinessConceptVersion{} = business_concept_version) do
    business_concept_version
    |> cast(%{}, [])
    |> put_change(:current, false)
  end

  @doc false
  def current_changeset(%BusinessConceptVersion{} = business_concept_version) do
    business_concept_version
    |> Map.get(:business_concept_id)
    |> BusinessConcepts.get_current_version_by_business_concept_id!(%{current: false})
    |> cast(%{}, [])
    |> put_change(:current, true)
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

  def search_fields(%BusinessConceptVersion{} = concept) do
    domain_id = concept.business_concept.domain_id
    aliases = BusinessConcepts.list_business_concept_aliases(concept.id)
    aliases = Enum.map(aliases, fn(a) -> %{name: a.name} end)
    domain_ids = Taxonomies.get_parent_ids(domain_id, true)

    %{domain_id: concept.business_concept.domain_id, name: concept.name, status: concept.status, type: concept.business_concept.type, content: concept.content,
      description: concept.description, last_change_at: concept.business_concept.last_change_at, bc_aliases: aliases, domain_ids: domain_ids, current: concept.current}
  end

  def index_name do
    "business_concept"
  end

end
