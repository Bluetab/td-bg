defmodule TdBg.Audit.AuditSupport do
  @moduledoc """
  Support module for publishing audit events.
  """

  alias Ecto.Changeset
  alias TdBg.BusinessConcepts
  alias TdBg.BusinessConcepts.BusinessConcept
  alias TdCache.Audit
  alias TdCache.TaxonomyCache
  alias TdDfLib.{MapDiff, Masks, Templates}

  def publish(
        event,
        resource_type,
        resource_id,
        user_id,
        payload \\ %{}
      )

  def publish(
        event,
        resource_type,
        resource_id,
        user_id,
        %Changeset{changes: changes, data: data}
      ) do
    payload = payload(changes, data)

    if map_size(changes) == 0 do
      {:ok, :unchanged}
    else
      Audit.publish(
        event: event,
        resource_type: resource_type,
        resource_id: resource_id,
        user_id: user_id,
        payload: add_event_via(payload)
      )
    end
  end

  def publish(event, resource_type, resource_id, user_id, payload) do
    Audit.publish(
      event: event,
      resource_type: resource_type,
      resource_id: resource_id,
      user_id: user_id,
      payload: add_event_via(payload)
    )
  end

  defp add_event_via(payload) do
    case Process.get(:event_via) do
      nil -> payload
      event_via -> Map.put(payload, :event_via, event_via)
    end
  end

  def subscribable_fields(%Changeset{data: data} = _changeset) do
    subscribable_fields(data)
  end

  def subscribable_fields(%{resource_id: id, resource_type: "business_concept"} = _resource) do
    id
    |> BusinessConcepts.get_business_concept_version("current")
    |> subscribable_fields()
  end

  def subscribable_fields(%{current: true, business_concept: %{type: type}, content: content}) do
    do_get_subscribable_fields(content, type)
  end

  def subscribable_fields(%{business_concept_id: id, business_concept: %{type: type}}) do
    id
    |> current_content()
    |> do_get_subscribable_fields(type)
  end

  def subscribable_fields(%BusinessConcept{id: id, type: type}) do
    id
    |> current_content()
    |> do_get_subscribable_fields(type)
  end

  def subscribable_fields(_), do: %{}

  def do_get_subscribable_fields(%{} = content, type) do
    Map.take(content, Templates.subscribable_fields(type))
  end

  def do_get_subscribable_fields(_, _), do: %{}

  defp current_content(business_concept_id) do
    business_concept_id
    |> BusinessConcepts.get_business_concept_version("current")
    |> case do
      version = %{} -> Map.get(version, :content)
      _ -> nil
    end
  end

  defp payload(%{description: description} = changes, data) do
    changes
    |> Map.delete(:description)
    |> payload(data)
    |> Map.put(:description, Masks.mask(description))
  end

  defp payload(%{last_change_at: _} = changes, data) do
    changes
    |> Map.drop([:last_change_at, :last_change_by])
    |> payload(data)
  end

  defp payload(%{business_concept: %Changeset{changes: business_concept_changes}} = changes, data) do
    business_concept_changes =
      Map.drop(business_concept_changes, [:last_change_by, :last_change_at])

    enriched_changes =
      case Map.get(business_concept_changes, :domain_id) do
        nil ->
          business_concept_changes

        _ ->
          enrich_domain_changes(business_concept_changes, data)
      end

    changes
    |> Map.delete(:business_concept)
    |> Map.merge(enriched_changes)
    |> payload(data)
  end

  defp payload(%{content: new_content} = changes, %{content: old_content} = _data)
       when is_map(new_content) or is_map(old_content) do
    merged_content = Map.merge(old_content, new_content)

    normalized_old = TdDfLib.Content.to_legacy(old_content)

    normalized_new =
      merged_content
      |> TdDfLib.Content.to_legacy()
      |> Enum.reject(fn {_k, v} -> v in [nil, ""] end)
      |> Map.new()

    diff = MapDiff.diff(normalized_old, normalized_new, mask: &Masks.mask/1)

    changes
    |> Map.delete(:content)
    |> Map.put(:content, diff)
  end

  defp payload(%{shared_to: shared_to} = changes, _data) do
    updated =
      shared_to
      |> Enum.filter(&(Map.get(&1, :action) == :update))
      |> Enum.map(& &1.data)
      |> Enum.map(&Map.take(&1, [:id, :external_id, :name]))

    changes
    |> Map.delete(:shared_to)
    |> Map.put(:shared_to, updated)
  end

  defp payload(%{domain_id: _domain_id} = changes, data), do: enrich_domain_changes(changes, data)

  defp payload(changes, _data), do: changes

  defp enrich_domain_changes(%{domain_id: domain_id} = changes, data) do
    changes
    |> Map.put(:domain_new, get_domain(domain_id))
    |> Map.put(:domain_old, get_domain(data))
  end

  defp get_domain(%{business_concept: %{domain: %{id: domain_id}}}) do
    get_domain(domain_id)
  end

  defp get_domain(%{domain: %{id: domain_id}}), do: get_domain(domain_id)

  defp get_domain(id) when is_integer(id) do
    case TaxonomyCache.get_domain(id) do
      nil -> nil
      domain -> Map.take(domain, [:external_id, :id, :name])
    end
  end

  defp get_domain(_), do: nil
end
