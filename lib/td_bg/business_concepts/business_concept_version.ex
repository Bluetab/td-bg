defmodule TdBg.BusinessConcepts.BusinessConceptVersion do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset
  alias TdBg.BusinessConcept.RichText
  alias TdBg.BusinessConcepts
  alias TdBg.BusinessConcepts.BusinessConcept
  alias TdBg.BusinessConcepts.BusinessConceptVersion
  alias TdBg.Searchable
  alias TdBg.Taxonomies
  alias TdCache.TaxonomyCache
  alias TdCache.TemplateCache
  alias TdCache.UserCache
  alias TdDfLib.Format

  @behaviour Searchable

  schema "business_concept_versions" do
    field(:content, :map)
    field(:related_to, {:array, :integer})
    field(:description, :map)
    field(:last_change_at, :utc_datetime_usec)
    field(:mod_comments, :string)
    field(:last_change_by, :integer)
    field(:name, :string)
    field(:reject_reason, :string)
    field(:status, :string)
    field(:current, :boolean, default: true)
    field(:version, :integer)
    field(:in_progress, :boolean, default: false)
    belongs_to(:business_concept, BusinessConcept, on_replace: :update)

    timestamps(type: :utc_datetime_usec)
  end

  @doc false
  def create_changeset(%BusinessConceptVersion{} = business_concept_version, attrs) do
    business_concept_version
    |> cast(attrs, [
      :content,
      :related_to,
      :name,
      :description,
      :last_change_by,
      :last_change_at,
      :version,
      :mod_comments,
      :in_progress
    ])
    |> put_assoc(:business_concept, attrs.business_concept)
    |> validate_required([
      :content,
      :related_to,
      :name,
      :last_change_by,
      :last_change_at,
      :version,
      :business_concept,
      :in_progress
    ])
    |> put_change(:status, BusinessConcept.status().draft)
    |> validate_length(:name, max: 255)
    |> validate_length(:mod_comments, max: 500)
  end

  def update_changeset(%BusinessConceptVersion{} = business_concept_version, attrs) do
    business_concept_version
    |> cast(attrs, [
      :content,
      :related_to,
      :name,
      :description,
      :last_change_by,
      :last_change_at,
      :mod_comments,
      :in_progress
    ])
    |> cast_assoc(:business_concept)
    |> put_change(:status, BusinessConcept.status().draft)
    |> validate_required([
      :content,
      :related_to,
      :name,
      :last_change_by,
      :last_change_at,
      :in_progress
    ])
    |> validate_length(:name, max: 255)
    |> validate_length(:mod_comments, max: 500)
  end

  @doc false
  def update_status_changeset(%BusinessConceptVersion{} = business_concept_version, attrs) do
    business_concept_version
    |> cast(attrs, [:status, :last_change_by, :last_change_at])
    |> validate_required([:status])
    |> validate_inclusion(:status, Map.values(BusinessConcept.status()))
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
    |> put_change(:status, BusinessConcept.status().rejected)
  end

  @doc false
  def changeset(%BusinessConceptVersion{} = business_concept_version, attrs) do
    business_concept_version
    |> cast(attrs, [
      :name,
      :description,
      :content,
      :last_change_by,
      :last_change_at,
      :status,
      :version,
      :reject_reason,
      :mod_comments,
      :in_progress
    ])
    |> validate_required([
      :name,
      :description,
      :content,
      :last_change_by,
      :last_change_at,
      :status,
      :version,
      :reject_reason,
      :mod_comments,
      :in_progress
    ])
  end

  def search_fields(
        %BusinessConceptVersion{
          last_change_by: last_change_by_id,
          business_concept: business_concept
        } = bcv
      ) do
    %{id: business_concept_id, type: type, domain_id: domain_id} = business_concept

    template =
      case TemplateCache.get_by_name!(type) do
        nil -> %{content: []}
        template -> template
      end

    domain = Taxonomies.get_domain(domain_id)
    domain_ids = Taxonomies.get_parent_ids(domain_id)

    domain_parents =
      domain_ids
      |> Enum.map(&%{id: &1, name: TaxonomyCache.get_name(&1)})

    last_change_by =
      case UserCache.get(last_change_by_id) do
        {:ok, nil} -> %{}
        {:ok, user} -> user
      end

    counts = BusinessConcepts.get_concept_counts(business_concept_id)
    bcv = Map.merge(bcv, counts)

    content =
      bcv
      |> Map.get(:content)
      |> Format.apply_template(Map.get(template, :content))

    content = update_in(content["_confidential"], &if(&1 == "Si", do: &1, else: "No"))

    bcv
    |> Map.take([
      :id,
      :business_concept_id,
      :name,
      :status,
      :version,
      :last_change_at,
      :current,
      :link_count,
      :rule_count,
      :in_progress,
      :inserted_at
    ])
    |> Map.put(:content, content)
    |> Map.put(:description, RichText.to_plain_text(bcv.description))
    |> Map.put(:domain, Map.take(domain, [:id, :name]))
    |> Map.put(:domain_ids, domain_ids)
    |> Map.put(:domain_parents, domain_parents)
    |> Map.put(:last_change_by, last_change_by)
    |> Map.put(:template, Map.take(template, [:name, :label]))
  end

  def index_name do
    "business_concept"
  end

  def has_any_status?(%BusinessConceptVersion{status: status}, statuses),
    do: has_any_status?(status, statuses)

  def has_any_status?(_status, []), do: false

  def has_any_status?(status, [h | t]) do
    status == h || has_any_status?(status, t)
  end

  def is_updatable?(%BusinessConceptVersion{current: current, status: status}) do
    current && status == BusinessConcept.status().draft
  end

  def is_publishable?(%BusinessConceptVersion{current: current, status: status}) do
    current && status == BusinessConcept.status().pending_approval
  end

  def is_rejectable?(%BusinessConceptVersion{} = business_concept_version),
    do: is_publishable?(business_concept_version)

  def is_versionable?(%BusinessConceptVersion{current: current, status: status}) do
    current && status == BusinessConcept.status().published
  end

  def is_deprecatable?(%BusinessConceptVersion{} = business_concept_version),
    do: is_versionable?(business_concept_version)

  def is_undo_rejectable?(%BusinessConceptVersion{current: current, status: status}) do
    current && status == BusinessConcept.status().rejected
  end

  def is_deletable?(%BusinessConceptVersion{current: current, status: status}) do
    valid_statuses = [BusinessConcept.status().draft, BusinessConcept.status().rejected]
    current && Enum.member?(valid_statuses, status)
  end
end
