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

  def publish(event, resource_type, resource_id, user_id, payload \\ %{})

  def publish(event, resource_type, resource_id, user_id, %Changeset{changes: changes, data: data}) do
    if map_size(changes) == 0 do
      {:ok, :unchanged}
    else
      Audit.publish(
        event: event,
        resource_type: resource_type,
        resource_id: resource_id,
        user_id: user_id,
        payload: payload(changes, data)
      )
    end
  end

  def publish(event, resource_type, resource_id, user_id, payload) do
    Audit.publish(
      event: event,
      resource_type: resource_type,
      resource_id: resource_id,
      user_id: user_id,
      payload: payload
    )
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

    changes
    |> Map.delete(:business_concept)
    |> Map.merge(business_concept_changes)
    |> payload(data)
  end

  defp payload(%{content: new_content} = changes, %{content: old_content} = _data)
       when is_map(new_content) or is_map(old_content) do
    diff = MapDiff.diff(old_content, new_content, mask: &Masks.mask/1)

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

  defp payload(%{domain_id: domain_id} = changes, data) do
    changes
    |> Map.put(:domain_new, get_domain(domain_id))
    |> Map.put(:domain_old, get_domain(data))
  end

  defp payload(changes, _data), do: changes

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
