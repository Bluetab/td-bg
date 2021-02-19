defmodule TdBg.Comments.Audit do
  @moduledoc """
  Manages the creation of audit events relating to comments
  """

  import TdBg.Audit.AuditSupport

  alias Ecto.Changeset
  alias TdBg.BusinessConcepts
  alias TdCache.TaxonomyCache

  @doc """
  Publishes a `:comment_created` event. Should be called using `Ecto.Multi.run/5`.
  """
  def comment_created(repo, %{resource: resource} = multi, changeset, user_id) do
    changeset =
      changeset
      |> Changeset.put_change(:domain_ids, domain_ids(resource))
      |> Changeset.put_change(:version_id, version_id(resource))
      |> Changeset.put_change(:resource_name, resource_name(resource))
      |> put_subscribable_ids(resource)

    comment_created(repo, Map.delete(multi, :resource), changeset, user_id)
  end

  def comment_created(_repo, %{comment: %{id: id}}, %{} = changeset, user_id) do
    publish("comment_created", "comment", id, user_id, changeset)
  end

  @doc """
  Publishes a `:comment_deleted` event. Should be called using `Ecto.Multi.run/5`.
  """
  def comment_deleted(_repo, %{comment: %{id: id}}, user_id) do
    publish("comment_deleted", "comment", id, user_id)
  end

  defp domain_ids(%{domain_id: domain_id}) when is_binary(domain_id) do
    domain_id
    |> String.to_integer()
    |> domain_ids()
  end

  defp domain_ids(domain_id) when is_integer(domain_id) do
    TaxonomyCache.get_parent_ids(domain_id)
  end

  defp domain_ids(_), do: nil

  defp version_id(%{ingest_version_id: id}), do: id
  defp version_id(%{business_concept_version_id: id}), do: id
  defp version_id(_), do: nil

  defp resource_name(%{name: name}), do: name
  defp resource_name(_), do: nil

  defp put_subscribable_ids(changeset, %{business_concept_version_id: id}) do
    fields =
      id
      |> BusinessConcepts.get_business_concept_version!()
      |> subscribable_fields()

    Changeset.put_change(changeset, :subscribable_fields, fields)
  end

  defp put_subscribable_ids(changeset, _) do
    changeset
  end
end
