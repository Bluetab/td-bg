defmodule TdBg.BusinessConcepts.Workflow do
  @moduledoc """
  The Business Concept Workflow context.
  """

  import Ecto.Query

  alias Ecto.Changeset
  alias Ecto.Multi
  alias TdBg.Auth.Claims
  alias TdBg.BusinessConcepts
  alias TdBg.BusinessConcepts.Audit
  alias TdBg.BusinessConcepts.BusinessConceptVersion
  alias TdBg.Cache.ConceptLoader
  alias TdBg.Repo
  alias TdCache.ConceptCache

  def deprecate_business_concept_version(
        %BusinessConceptVersion{} = business_concept_version,
        %Claims{} = claims
      ) do
    result =
      update_business_concept_version_status(business_concept_version, "deprecated", claims)

    ConceptCache.delete(business_concept_version.business_concept_id)
    result
  end

  @spec submit_business_concept_version(
          TdBg.BusinessConcepts.BusinessConceptVersion.t(),
          TdBg.Auth.Claims.t()
        ) :: any
  def submit_business_concept_version(
        %BusinessConceptVersion{} = business_concept_version,
        %Claims{} = claims
      ) do
    update_business_concept_version_status(business_concept_version, "pending_approval", claims)
  end

  def undo_rejected_business_concept_version(
        %BusinessConceptVersion{} = business_concept_version,
        %Claims{} = claims
      ) do
    update_business_concept_version_status(business_concept_version, "draft", claims)
  end

  defp update_business_concept_version_status(
         %BusinessConceptVersion{} = business_concept_version,
         status,
         %Claims{user_id: user_id}
       ) do
    changeset = BusinessConceptVersion.status_changeset(business_concept_version, status, user_id)

    Multi.new()
    |> Multi.update(:updated, changeset)
    |> Multi.run(:audit, Audit, :status_updated, [changeset])
    |> Repo.transaction()
    |> case do
      {:ok, %{updated: updated}} = result ->
        business_concept_id = updated.business_concept_id
        ConceptLoader.refresh(business_concept_id)
        result

      error ->
        error
    end
  end

  def publish(business_concept_version, %Claims{user_id: user_id}) do
    business_concept_id = business_concept_version.business_concept.id

    query =
      from(
        c in BusinessConceptVersion,
        where: c.business_concept_id == ^business_concept_id and c.status == "published"
      )

    changeset =
      business_concept_version
      |> BusinessConceptVersion.status_changeset("published", user_id)
      |> Changeset.change(current: true)

    result =
      Multi.new()
      |> Multi.update_all(:versioned, query, set: [status: "versioned", current: false])
      |> Multi.update(:published, changeset)
      |> Multi.run(:audit, Audit, :business_concept_published, [])
      |> Repo.transaction()

    case result do
      {:ok, %{published: %BusinessConceptVersion{business_concept_id: business_concept_id}}} ->
        ConceptLoader.refresh(business_concept_id)
        result

      _ ->
        result
    end
  end

  def reject(
        %BusinessConceptVersion{} = business_concept_version,
        reason,
        %Claims{user_id: user_id}
      ) do
    params = %{reject_reason: reason}
    changeset = BusinessConceptVersion.reject_changeset(business_concept_version, params, user_id)

    Multi.new()
    |> Multi.update(:rejected, changeset)
    |> Multi.run(:audit, Audit, :business_concept_rejected, [])
    |> Repo.transaction()
    |> case do
      {:ok, %{rejected: %{business_concept_id: id}}} = result ->
        ConceptLoader.refresh(id)
        result

      error ->
        error
    end
  end

  @doc """
  Creates a new business_concept version.
  """
  def new_version(%BusinessConceptVersion{} = business_concept_version, %Claims{user_id: user_id}) do
    business_concept = business_concept_version.business_concept

    business_concept =
      business_concept
      |> Map.put("last_change_by", user_id)
      |> Map.put("last_change_at", DateTime.utc_now())

    draft_attrs = Map.from_struct(business_concept_version)

    draft_attrs =
      draft_attrs
      |> Map.put("business_concept", business_concept)
      |> Map.put("last_change_by", user_id)
      |> Map.put("last_change_at", DateTime.utc_now())
      |> Map.put("status", "draft")
      |> Map.put("version", business_concept_version.version + 1)

    result =
      draft_attrs
      |> BusinessConcepts.attrs_keys_to_atoms()
      |> BusinessConcepts.validate_new_concept(business_concept_version)
      |> do_new_version()

    case result do
      {:ok, %{current: new_version}} ->
        business_concept_id = new_version.business_concept_id
        ConceptLoader.refresh(business_concept_id)
        result

      _ ->
        result
    end
  end

  defp do_new_version(%{changeset: changeset}) do
    Multi.new()
    |> Multi.insert(:current, Changeset.change(changeset, current: false))
    |> Multi.run(:audit, Audit, :business_concept_versioned, [])
    |> Repo.transaction()
  end
end
