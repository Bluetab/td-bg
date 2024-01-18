defmodule TdBg.BusinessConcepts.Audit do
  @moduledoc """
  Manages the creation of audit events relating to business concepts
  """

  import Ecto.Query
  import TdBg.Audit.AuditSupport

  alias Ecto.Changeset
  alias TdBg.BusinessConcepts.{BusinessConcept, BusinessConceptVersion}
  alias TdBg.Repo
  alias TdCache.TaxonomyCache

  def business_concepts_created(concept_ids) do
    audit_fields = [
      :content,
      :in_progress,
      :last_change_at,
      :last_change_by,
      :name,
      :status,
      :version,
      :business_concept_id,
      business_concept: [:domain_id, :last_change_at, :last_change_by, :type]
    ]

    BusinessConceptVersion
    |> where([v], v.business_concept_id in ^concept_ids)
    |> where([v], v.version == 1)
    |> preload(business_concept: [:domain])
    |> select([v], map(v, ^audit_fields))
    |> Repo.all()
    |> Enum.map(&Map.pop(&1, :business_concept_id))
    |> Enum.map(&business_concept_created/1)
    |> Enum.group_by(&elem(&1, 0), &elem(&1, 1))
    |> case do
      %{error: errors} -> {:error, errors}
      %{ok: event_ids} -> {:ok, event_ids}
    end
  end

  def business_concept_created(_repo, %{business_concept_version: business_concept_version}) do
    business_concept_created(business_concept_version)
  end

  def business_concept_created(%BusinessConceptVersion{business_concept_id: business_concept_id}) do
    business_concepts_created([business_concept_id])
  end

  def business_concept_created({id, %{last_change_by: user_id} = payload}) do
    fields =
      payload
      |> Map.put(:business_concept_id, id)
      |> subscribable_fields()

    payload =
      payload
      |> Map.put(:subscribable_fields, fields)
      |> Map.put(:domain_ids, get_domain_ids(payload))

    publish("new_concept_draft", "concept", id, user_id, payload)
  end

  def business_concept_updated(_repo, _payload, %Changeset{changes: changes})
      when map_size(changes) == 0 do
    {:ok, :unchanged}
  end

  def business_concept_updated(_repo, %{updated: updated}, changeset) do
    case updated do
      %BusinessConceptVersion{business_concept_id: id, last_change_by: user_id} ->
        changeset = do_changeset_updated(changeset, updated)
        publish("update_concept_draft", "concept", id, user_id, changeset)

      %BusinessConcept{id: id, last_change_by: user_id} ->
        changeset = do_changeset_updated(changeset, updated)
        publish("update_concept", "concept", id, user_id, changeset)
    end
  end

  def business_concept_published(_repo, %{published: business_concept_version}) do
    case business_concept_version do
      %{business_concept_id: id, last_change_by: user_id} ->
        payload = status_payload(business_concept_version)
        publish("concept_published", "concept", id, user_id, payload)
    end
  end

  def business_concept_rejected(_repo, %{rejected: business_concept_version}) do
    case business_concept_version do
      %{business_concept_id: id, last_change_by: user_id} ->
        payload = status_payload(business_concept_version)
        publish("concept_rejected", "concept", id, user_id, payload)
    end
  end

  def business_concept_versioned(_repo, %{current: current}) do
    case current do
      %{business_concept_id: id, last_change_by: user_id} ->
        payload = status_payload(current)
        publish("new_concept_draft", "concept", id, user_id, payload)
    end
  end

  def business_concept_deleted(
        _repo,
        %{business_concept_version: business_concept_version},
        user_id
      ) do
    case business_concept_version do
      %{business_concept_id: id} ->
        payload = status_payload(business_concept_version)
        publish("delete_concept_draft", "concept", id, user_id, payload)
    end
  end

  def status_updated(_repo, %{updated: business_concept_version}, %Changeset{} = changeset) do
    changeset
    |> Changeset.fetch_change!(:status)
    |> do_status_updated(business_concept_version)
  end

  defp do_changeset_updated(changeset, updated) do
    changeset
    |> Changeset.put_change(:subscribable_fields, subscribable_fields(changeset))
    |> Changeset.put_change(:domain_ids, get_domain_ids(updated))
  end

  defp do_status_updated("pending_approval", business_concept_version) do
    case business_concept_version do
      %{business_concept_id: id, last_change_by: user_id} ->
        payload = status_payload(business_concept_version)
        publish("concept_submitted", "concept", id, user_id, payload)
    end
  end

  defp do_status_updated("deprecated", business_concept_version) do
    case business_concept_version do
      %{business_concept_id: id, last_change_by: user_id} ->
        payload = status_payload(business_concept_version)
        publish("concept_deprecated", "concept", id, user_id, payload)
    end
  end

  defp do_status_updated("draft", business_concept_version) do
    case business_concept_version do
      %{business_concept_id: id, last_change_by: user_id} ->
        payload = status_payload(business_concept_version)
        publish("concept_rejection_canceled", "concept", id, user_id, payload)
    end
  end

  defp status_payload(business_concept_version) do
    business_concept_version
    |> Map.take([:version, :id, :name])
    |> Map.put(:domain_ids, get_domain_ids(business_concept_version))
    |> Map.put(:subscribable_fields, subscribable_fields(business_concept_version))
  end

  defp get_domain_ids(%{business_concept: business_concept}) do
    get_domain_ids(business_concept)
  end

  defp get_domain_ids(%{domain_id: domain_id}) do
    TaxonomyCache.reaching_domain_ids(domain_id)
  end

  defp get_domain_ids(_), do: []
end
