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
    |> Enum.map(fn {id, payload} -> business_concept_created({id, payload}) end)
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

    publish("create_concept_draft", "concept", id, user_id, payload)
  end

  def business_concept_updated(_repo, _payload, %Changeset{changes: changes})
      when map_size(changes) == 0 do
    {:ok, :unchanged}
  end

  def business_concept_updated(
        repo,
        %{updated: %BusinessConceptVersion{business_concept: business_concept}},
        changeset
      ) do
    business_concept_updated(repo, business_concept, changeset)
  end

  def business_concept_updated(
        repo,
        %{updated: %BusinessConcept{} = business_concept},
        changeset
      ) do
    business_concept_updated(repo, business_concept, changeset)
  end

  def business_concept_updated(_repo, %BusinessConcept{} = updated, changeset) do
    %{id: id, last_change_by: user_id} = updated

    changeset = do_changeset_updated(changeset, updated)

    publish("update_concept", "concept", id, user_id, changeset)
  end

  def business_concept_version_updated(_repo, _payload, %Changeset{changes: changes})
      when map_size(changes) == 0 do
    {:ok, :unchanged}
  end

  def business_concept_version_updated(
        _repo,
        %{updated: updated} = payload,
        changeset
      ) do
    old_version = Map.get(payload, :old_version)
    %BusinessConceptVersion{business_concept_id: id, last_change_by: user_id} = updated
    changeset = do_changeset_updated(changeset, updated)

    event =
      cond do
        Process.get(:event_via) == "file" ->
          "update_concept_draft"

        Map.get(updated, :status) == "published" ->
          "update_concept"

        true ->
          "update_concept_draft"
      end

    changeset =
      if old_version do
        Map.update!(changeset, :changes, &Map.put(&1, :original_version, old_version))
      else
        changeset
      end

    publish(event, "concept", id, user_id, changeset)
  end

  def business_concept_published(
        repo,
        %{published: business_concept_version} = changes,
        changeset \\ nil
      ) do
    case business_concept_version do
      %{business_concept_id: id, last_change_by: user_id} ->
        if not is_nil(changeset) do
          old_version = Map.get(changes, :old_version, %{})

          business_concept_versioned(
            repo,
            %{updated: business_concept_version, old_version: old_version},
            changeset
          )
        end

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

  def business_concept_versioned(repo, %{current: current} = changes, changeset_or_map) do
    old_version = Map.get(changes, :old_version, %{})

    changeset_or_map
    |> unwrap_changeset()
    |> do_business_concept_versioned(repo, current, old_version)
  end

  def business_concept_versioned(repo, %{updated: updated} = changes, changeset_or_map) do
    old_version = Map.get(changes, :old_version, %{})

    changeset_or_map
    |> unwrap_changeset()
    |> do_business_concept_versioned(repo, updated, old_version)
  end

  defp unwrap_changeset(%{changeset: changeset}), do: changeset
  defp unwrap_changeset(%Changeset{} = changeset), do: changeset
  defp unwrap_changeset(_), do: nil

  defp do_business_concept_versioned(changeset, repo, version, old_version) do
    case version do
      %{business_concept_id: id, last_change_by: user_id} ->
        payload = status_payload(version)
        {:ok, event_id} = publish("new_concept_draft", "concept", id, user_id, payload)

        if Process.get(:event_via) == "file" and not is_nil(changeset) do
          business_concept_version_updated(
            repo,
            %{updated: version, old_version: old_version},
            changeset
          )
        else
          {:ok, event_id}
        end
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
    payload =
      business_concept_version
      |> Map.take([:version, :id, :name])
      |> Map.put(:domain_ids, get_domain_ids(business_concept_version))
      |> Map.put(:subscribable_fields, subscribable_fields(business_concept_version))

    case Process.get(:event_via) do
      nil -> payload
      event_via -> Map.put(payload, :event_via, event_via)
    end
  end

  defp get_domain_ids(%{business_concept: business_concept}) do
    get_domain_ids(business_concept)
  end

  defp get_domain_ids(%{domain_id: domain_id}) do
    TaxonomyCache.reaching_domain_ids(domain_id)
  end

  defp get_domain_ids(_), do: []
end
