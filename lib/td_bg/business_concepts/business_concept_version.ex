defmodule TdBg.BusinessConcepts.BusinessConceptVersion do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset
  alias TdBg.BusinessConcepts
  alias TdBg.BusinessConcepts.BusinessConcept
  alias TdBg.BusinessConcepts.BusinessConceptVersion
  alias TdBg.Searchable
  alias TdBg.Taxonomies

  @behaviour Searchable

  @td_auth_api Application.get_env(:td_bg, :auth_service)[:api_service]

  schema "business_concept_versions" do
    field(:content, :map)
    field(:related_to, {:array, :integer})
    field(:description, :string)
    field(:last_change_at, :utc_datetime)
    field(:mod_comments, :string)
    field(:last_change_by, :integer)
    field(:name, :string)
    field(:reject_reason, :string)
    field(:status, :string)
    field(:current, :boolean, default: true)
    field(:version, :integer)
    belongs_to(:business_concept, BusinessConcept, on_replace: :update)

    timestamps()
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
      :mod_comments
    ])
    |> put_assoc(:business_concept, attrs.business_concept)
    |> validate_required([
      :content,
      :related_to,
      :name,
      :last_change_by,
      :last_change_at,
      :version,
      :business_concept
    ])
    |> put_change(:status, BusinessConcept.status().draft)
    |> validate_length(:name, max: 255)
    |> validate_length(:description, max: 500)
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
      :mod_comments
    ])
    |> cast_assoc(:business_concept)
    |> put_change(:status, BusinessConcept.status().draft)
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
      :mod_comments
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
      :mod_comments
    ])
  end

  def search_fields(%BusinessConceptVersion{last_change_by: last_change_by_id} = concept) do
    domain = Taxonomies.get_domain!(concept.business_concept.domain_id)
    aliases = BusinessConcepts.list_business_concept_aliases(concept.id)
    aliases = Enum.map(aliases, &%{name: &1.name})
    domain_ids = Taxonomies.get_parent_ids(domain.id, true)
    # TODO: Cache user list for indexing instead of querying for every document
    last_change_by = case @td_auth_api.get_user(last_change_by_id) do
      nil -> %{}
      user -> user |> Map.take(["id", "user_name", "full_name"])
    end

    %{
      id: concept.id,
      business_concept_id: concept.business_concept.id,
      name: concept.name,
      description: concept.description,
      status: concept.status,
      version: concept.version,
      domain: %{
        id: domain.id,
        name: domain.name
      },
      last_change_by: last_change_by,
      type: concept.business_concept.type,
      content: concept.content,
      last_change_at: concept.business_concept.last_change_at,
      bc_aliases: aliases,
      domain_ids: domain_ids,
      current: concept.current,
      link_count: concept.link_count,
      q_rule_count: concept.q_rule_count
    }
  end

  def index_name do
    "business_concept"
  end

  def has_any_status?(%BusinessConceptVersion{status: status}, statuses), do: has_any_status?(status, statuses)
  def has_any_status?(_status, []), do: false
  def has_any_status?(status, [h|t]) do
    status == h || has_any_status?(status, t)
  end

  def is_updatable?(%BusinessConceptVersion{current: current, status: status}) do
    current && status == BusinessConcept.status().draft
  end
  def is_publishable?(%BusinessConceptVersion{current: current, status: status}) do
    current && status == BusinessConcept.status().pending_approval
  end
  def is_rejectable?(%BusinessConceptVersion{} = business_concept_version), do: is_publishable?(business_concept_version)
  def is_versionable?(%BusinessConceptVersion{current: current, status: status}) do
    current && status == BusinessConcept.status().published
  end
  def is_deprecatable?(%BusinessConceptVersion{} = business_concept_version), do: is_versionable?(business_concept_version)
  def is_undo_rejectable?(%BusinessConceptVersion{current: current, status: status}) do
    current && status == BusinessConcept.status().rejected
  end
  def is_deletable?(%BusinessConceptVersion{current: current, status: status}) do
    valid_statuses = [BusinessConcept.status().draft, BusinessConcept.status().rejected]
    current && Enum.member?(valid_statuses, status)
  end

end
