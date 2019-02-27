defmodule TdBg.BusinessConcepts.Events do
  @moduledoc """
  Manages the creation of audit events relating to business concepts
  """

  import Ecto.Query

  alias TdBg.Audit
  alias TdBg.BusinessConcepts
  alias TdBg.BusinessConcepts.BusinessConceptVersion
  alias TdBg.Repo
  alias TdPerms.UserCache

  def business_concepts_created(concept_ids) do
    audit_fields = [
      :content,
      :description,
      :in_progress,
      :last_change_at,
      :last_change_by,
      :name,
      :related_to,
      :status,
      :version,
      :business_concept_id,
      business_concept: [:domain_id, :last_change_at, :last_change_by, :parent_id, :type]
    ]

    BusinessConceptVersion
    |> where([v], v.business_concept_id in ^concept_ids)
    |> where([v], v.version == 1)
    |> preload(business_concept: [:domain])
    |> select([v], map(v, ^audit_fields))
    |> Repo.all()
    |> Enum.map(&Map.pop(&1, :business_concept_id))
    |> Enum.map(&business_concept_created/1)
  end

  def business_concept_created(%BusinessConceptVersion{business_concept_id: business_concept_id}) do
    business_concepts_created([business_concept_id])
  end

  def business_concept_created({id, %{last_change_at: ts, last_change_by: user_id} = payload}) do
    publish_event(payload, :create_concept_draft, id, user_id, ts)
  end

  def business_concept_updated(
        %BusinessConceptVersion{} = old,
        %BusinessConceptVersion{
          business_concept_id: id,
          last_change_at: ts,
          last_change_by: user_id
        } = new
      ) do
    old
    |> BusinessConcepts.diff(new)
    |> publish_event(:update_concept_draft, id, user_id, ts)
  end

  def business_concept_submitted(business_concept_version) do
    business_concept_status_change(business_concept_version, :concept_sent_for_approval)
  end

  def business_concept_published(business_concept_version) do
    business_concept_status_change(business_concept_version, :concept_published)
  end

  def business_concept_rejected(business_concept_version) do
    business_concept_status_change(business_concept_version, :concept_rejected)
  end

  def business_concept_deprecated(business_concept_version) do
    business_concept_status_change(business_concept_version, :concept_deprecated)
  end

  def business_concept_redrafted(business_concept_version) do
    business_concept_status_change(business_concept_version, :concept_rejection_canceled)
  end

  def business_concept_versioned(%BusinessConceptVersion{
        version: version,
        business_concept_id: business_concept_id,
        last_change_by: user_id,
        last_change_at: ts
      }) do
    payload = %{version: version}
    publish_event(payload, :new_concept_draft, business_concept_id, user_id, ts)
  end

  def business_concept_deleted(
        %BusinessConceptVersion{version: version, business_concept_id: business_concept_id},
        user_id
      ) do
    payload = %{version: version}
    ts = DateTime.utc_now()

    publish_event(payload, :delete_concept_draft, business_concept_id, user_id, ts)
  end

  defp business_concept_status_change(
         %BusinessConceptVersion{
           business_concept_id: id,
           last_change_by: user_id,
           last_change_at: ts
         },
         event_type
       ) do
    publish_event(%{}, event_type, id, user_id, ts)
  end

  defp publish_event(payload, event_type, resource_id, user_id, ts) do
    user_name =
      case UserCache.get_user(user_id) do
        %{full_name: name} -> name
        _ -> ""
      end

    %{
      event: event_type,
      ts: DateTime.to_string(ts),
      resource_type: :concept,
      resource_id: resource_id,
      payload: payload,
      user_id: user_id,
      user_name: user_name
    }
    |> Audit.publish_event()
  end
end
