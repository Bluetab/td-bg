defmodule TdBg.BusinessConcepts.BusinessConceptVersion do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset

  alias TdBg.BusinessConcepts
  alias TdBg.BusinessConcepts.BusinessConcept
  alias TdBg.BusinessConcepts.BusinessConceptVersion
  alias TdBg.Taxonomies
  alias TdDfLib.Format
  alias TdDfLib.Validation

  @valid_status ["draft", "pending_approval", "rejected", "published", "versioned", "deprecated"]

  schema "business_concept_versions" do
    field(:content, :map)
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
    field(:domain_ids, {:array, :integer}, virtual: true)
    field(:subscribable_fields, {:array, :string}, virtual: true)
    belongs_to(:business_concept, BusinessConcept, on_replace: :update)

    timestamps(type: :utc_datetime_usec)
  end

  def create_changeset(
        %BusinessConceptVersion{} = business_concept_version,
        params,
        old_business_concept_version \\ %BusinessConceptVersion{}
      ) do
    business_concept_version
    |> cast(params, [
      :content,
      :name,
      :description,
      :last_change_by,
      :last_change_at,
      :version,
      :mod_comments,
      :in_progress
    ])
    |> put_assoc(:business_concept, params.business_concept)
    |> validate_required([
      :content,
      :name,
      :last_change_by,
      :last_change_at,
      :version,
      :business_concept,
      :in_progress
    ])
    |> maybe_put_identifier(params, old_business_concept_version)
    |> put_change(:status, "draft")
    |> update_change(:name, &String.trim/1)
    |> validate_length(:name, max: 255)
    |> validate_length(:mod_comments, max: 500)
    |> validate_change(:description, &Validation.validate_safe/2)
    |> validate_change(:content, &Validation.validate_safe/2)
  end

  def update_changeset(business_concept_version, params) do
    business_concept_version
    |> cast(params, [
      :content,
      :name,
      :description,
      :last_change_by,
      :last_change_at,
      :mod_comments,
      :in_progress
    ])
    |> cast_assoc(:business_concept)
    |> put_change(:status, "draft")
    |> validate_required([
      :content,
      :name,
      :last_change_by,
      :last_change_at,
      :in_progress
    ])
    |> maybe_put_identifier(business_concept_version)
    |> update_change(:name, &String.trim/1)
    |> validate_length(:name, max: 255)
    |> validate_length(:mod_comments, max: 500)
    |> validate_change(:description, &Validation.validate_safe/2)
    |> validate_change(:content, &Validation.validate_safe/2)
  end

  def bulk_update_changeset(
        %BusinessConceptVersion{} = business_concept_version,
        params
      ) do
    business_concept_version
    |> update_changeset(params)
    |> delete_change(:status)
    |> maybe_put_identifier(business_concept_version)
    |> validate_name(business_concept_version)
  end

  defp maybe_put_identifier(
         changeset,
         _params,
         %BusinessConceptVersion{content: _old_content, business_concept: %{type: _template_name}} =
           business_concept_version
       ) do
    maybe_put_identifier(changeset, business_concept_version)
  end

  defp maybe_put_identifier(
         changeset,
         %{business_concept: %{type: _template_name}} = params,
         _business_concept_version
       ) do
    maybe_put_identifier(changeset, params)
  end

  defp maybe_put_identifier(changeset, _params, _business_concept_version), do: changeset

  defp maybe_put_identifier(changeset, %BusinessConceptVersion{
         content: old_content,
         business_concept: %{type: template_name}
       }) do
    maybe_put_identifier_aux(changeset, old_content, template_name)
  end

  defp maybe_put_identifier(changeset, %{business_concept: %{type: template_name}} = _params) do
    maybe_put_identifier_aux(changeset, %{}, template_name)
  end

  defp maybe_put_identifier_aux(
         %{valid?: true, changes: %{content: changeset_content}} = changeset,
         old_content,
         template_name
       ) do
    new_content = Format.maybe_put_identifier(changeset_content, old_content, template_name)

    put_change(changeset, :content, new_content)
  end

  defp maybe_put_identifier_aux(changeset, _old_content, _template_name) do
    changeset
  end

  defp validate_name(
         %{changes: %{business_concept: %{changes: %{domain_id: domain_id}}}, valid?: true} =
           changeset,
         business_concept_version
       ) do
    %{name: name, business_concept: business_concept} =
      Map.take(business_concept_version, [:name, :business_concept])

    type = Map.get(business_concept, :type)

    domain_group =
      domain_id
      |> Taxonomies.get_domain!([:domain_group])
      |> Map.get(:domain_group)

    domain_group_id = Map.get(domain_group || %{}, :id)

    case BusinessConcepts.check_business_concept_name_availability(type, name,
           business_concept_id: business_concept.id,
           domain_group_id: domain_group_id
         ) do
      :ok ->
        changeset

      {:error, :name_not_available} ->
        add_error(changeset, :name, "error.existing.business_concept.name")
    end
  end

  defp validate_name(changeset, _business_concept_version), do: changeset

  def confidential_changeset(%BusinessConceptVersion{} = business_concept_version, params) do
    business_concept_version
    |> update_changeset(params)
    |> delete_change(:status)
  end

  def status_changeset(%BusinessConceptVersion{} = business_concept_version, status, user_id) do
    business_concept_version
    |> cast(%{status: status}, [:status])
    |> validate_required(:status)
    |> validate_inclusion(:status, @valid_status)
    |> put_audit(user_id)
  end

  def reject_changeset(
        %BusinessConceptVersion{} = business_concept_version,
        %{} = params,
        user_id
      ) do
    business_concept_version
    |> cast(params, [:reject_reason])
    |> validate_length(:reject_reason, max: 500)
    |> put_change(:status, "rejected")
    |> put_audit(user_id)
  end

  def changeset(%BusinessConceptVersion{} = business_concept_version, params) do
    business_concept_version
    |> cast(params, [
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
    |> update_change(:name, &String.trim/1)
    |> validate_change(:description, &Validation.validate_safe/2)
    |> validate_change(:content, &Validation.validate_safe/2)
  end

  defp put_audit(%{changes: changes} = changeset, _user_id) when changes == %{}, do: changeset

  defp put_audit(%{} = changeset, user_id) do
    changeset
    |> put_change(:last_change_by, user_id)
    |> put_change(:last_change_at, DateTime.utc_now())
  end

  def has_any_status?(%BusinessConceptVersion{status: status}, statuses),
    do: has_any_status?(status, statuses)

  def has_any_status?(_status, []), do: false

  def has_any_status?(status, [h | t]) do
    status == h || has_any_status?(status, t)
  end

  def is_updatable?(%BusinessConceptVersion{status: status} = bcv) do
    BusinessConcepts.last?(bcv) && status == "draft"
  end

  def is_publishable?(%BusinessConceptVersion{status: status} = bcv) do
    BusinessConcepts.last?(bcv) && status in ["pending_approval"]
  end

  def is_restorable?(%BusinessConceptVersion{status: status} = bcv) do
    BusinessConcepts.last?(bcv) && status in ["deprecated"]
  end

  def is_rejectable?(business_concept_version),
    do: is_publishable?(business_concept_version)

  def is_versionable?(%BusinessConceptVersion{status: status} = bcv) do
    BusinessConcepts.last?(bcv) && status == "published"
  end

  def is_deprecatable?(%BusinessConceptVersion{} = business_concept_version),
    do: is_versionable?(business_concept_version)

  def is_undo_rejectable?(%BusinessConceptVersion{status: status} = bcv) do
    BusinessConcepts.last?(bcv) && status == "rejected"
  end

  def is_deletable?(%BusinessConceptVersion{status: status} = bcv) do
    valid_statuses = ["draft", "rejected"]
    BusinessConcepts.last?(bcv) && Enum.member?(valid_statuses, status)
  end

  defimpl Elasticsearch.Document do
    alias TdBg.Taxonomies
    alias TdCache.TemplateCache
    alias TdCache.UserCache
    alias TdDfLib.Format
    alias TdDfLib.RichText

    @impl Elasticsearch.Document
    def id(%BusinessConceptVersion{id: id}), do: id

    @impl Elasticsearch.Document
    def routing(_), do: false

    @impl Elasticsearch.Document
    def encode(%BusinessConceptVersion{business_concept: business_concept} = bcv) do
      %{type: type, domain: domain, confidential: confidential, shared_to: shared_to} =
        business_concept

      template = TemplateCache.get_by_name!(type) || %{content: []}
      domain_ids = get_domain_ids(domain, shared_to)
      shared_to = get_shared_to(shared_to)
      shared_to_names = shared_to_names(shared_to)

      content =
        bcv
        |> Map.get(:content)
        |> Format.search_values(template, domain_id: domain.id)

      bcv
      |> Map.take([
        :id,
        :business_concept_id,
        :name,
        :status,
        :version,
        :last_change_at,
        :current,
        :concept_count,
        :in_progress,
        :inserted_at
      ])
      |> Map.merge(BusinessConcepts.get_concept_counts(bcv.business_concept_id))
      |> Map.put(:content, content)
      |> Map.put(:description, RichText.to_plain_text(bcv.description))
      |> Map.put(:domain, Map.take(domain, [:id, :name, :external_id]))
      |> Map.put(:domain_ids, domain_ids)
      |> Map.put(:last_change_by, get_last_change_by(bcv))
      |> Map.put(:template, Map.take(template, [:name, :label, :scope, :subscope]))
      |> Map.put(:confidential, confidential)
      |> Map.put(:shared_to_names, shared_to_names)
    end

    defp get_last_change_by(%BusinessConceptVersion{last_change_by: last_change_by}) do
      get_user(last_change_by)
    end

    defp get_user(user_id) do
      case UserCache.get(user_id) do
        {:ok, nil} -> %{}
        {:ok, user} -> user
      end
    end

    defp get_shared_to(shared_to) do
      shared_to
      |> Enum.map(&Taxonomies.get_parents(&1.id))
      |> List.flatten()
      |> Enum.filter(& &1)
      |> Enum.uniq_by(& &1.id)
    end

    defp get_domain_ids(domain, shared_to) do
      Enum.map([domain | List.wrap(shared_to)], & &1.id)
    end

    defp shared_to_names([]), do: nil

    defp shared_to_names(shared_to), do: Enum.map(shared_to, & &1.name)
  end
end
