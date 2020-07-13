defmodule TdBg.Taxonomies.Domain do
  @moduledoc """
  Ecto schema representing a domain in the business glossary.
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias Ecto.Changeset
  alias TdBg.BusinessConcepts
  alias TdBg.BusinessConcepts.BusinessConcept
  alias TdBg.Groups.DomainGroup
  alias TdBg.Taxonomies
  alias TdBg.Utils.CollectionUtils

  schema "domains" do
    field(:description, :string)
    field(:type, :string)
    field(:name, :string)
    field(:external_id, :string)
    field(:deleted_at, :utc_datetime_usec)
    belongs_to(:parent, __MODULE__)
    belongs_to(:domain_group, DomainGroup, on_replace: :nilify)
    has_many(:business_concepts, BusinessConcept)

    timestamps(type: :utc_datetime_usec)
  end

  def changeset(%{} = params) do
    changeset(%__MODULE__{}, params)
  end

  def changeset(%__MODULE__{} = domain, attrs) do
    domain
    |> cast(attrs, [:name, :type, :description, :parent_id, :external_id, :domain_group_id])
    |> validate_required([:name])
    |> put_group(attrs, domain)
    |> unique_constraint(:external_id)
    |> unique_constraint(:name, name: :domains_name_index)
    |> unique_constraint([:name, :domain_group_id], name: :domains_domain_group_id_name_index)
    |> validate_parent_id(domain)
    |> foreign_key_constraint(:parent_id, name: :domains_parent_id_fkey)
    |> foreign_key_constraint(:domain_group_id, name: :domains_domain_group_id_fkey)
  end

  def delete_changeset(%__MODULE__{} = domain) do
    change(domain, deleted_at: DateTime.utc_now())
  end

  defp put_group(
         %Changeset{valid?: true} = changeset,
         %{
           domain_group: domain_group,
           descendents: descendents
         },
         %__MODULE__{id: id}
       ) do
    group_id = Map.get(domain_group || %{}, :id)
    domain_ids = [id | Enum.map(descendents, & &1.id)]
    changeset = validate_concept_names(changeset, group_id, domain_ids)
    put_group(changeset, %{domain_group: domain_group})
  end

  defp put_group(
         %Changeset{valid?: true} = changeset,
         %{
           domain_group: domain_group
         },
         _domain
       ) do
    put_group(changeset, %{domain_group: domain_group})
  end

  defp put_group(%Changeset{} = changeset, _domain, _changes), do: changeset

  defp put_group(%Changeset{valid?: true} = changeset, %{domain_group: domain_group}) do
    put_assoc(changeset, :domain_group, domain_group)
  end

  defp put_group(%Changeset{} = changeset, _changes), do: changeset

  defp validate_parent_id(%Ecto.Changeset{valid?: false} = changeset, _domain), do: changeset
  defp validate_parent_id(%Ecto.Changeset{} = changeset, %__MODULE__{id: nil}), do: changeset

  defp validate_parent_id(
         %Ecto.Changeset{changes: %{parent_id: parent_id}} = changeset,
         %__MODULE__{id: id}
       )
       when not is_nil(parent_id) do
    descendent_ids = Taxonomies.descendent_ids(id)
    validate_exclusion(changeset, :parent_id, descendent_ids)
  end

  defp validate_parent_id(%Ecto.Changeset{} = changeset, %__MODULE__{}), do: changeset

  defp validate_concept_names(changeset, group_id, domain_ids) do
    grouped_from_group =
      group_id
      |> BusinessConcepts.get_active_concepts_in_group()
      |> grouped_by_type()

    grouped_from_domain =
      domain_ids
      |> BusinessConcepts.get_active_concepts_by_domain_ids()
      |> grouped_by_type()

    grouped_from_group
    |> CollectionUtils.map_intersection(grouped_from_domain)
    |> Enum.map(fn {k, v} -> {k, MapSet.to_list(v)} end)
    |> Enum.find(fn {_k, v} -> v != [] end)
    |> case do
      nil -> changeset
      _ -> add_error(changeset, :business_concept, "domain.error.existing.business_concept.name")
    end
  end

  defp grouped_by_type(collection) do
    collection
    |> Enum.group_by(&Map.get(&1, :type))
    |> Enum.map(fn {k, v} -> {k, to_names_map_set(v)} end)
    |> Enum.into(%{})
  end

  defp to_names_map_set(collection) do
    collection
    |> Enum.map(&String.downcase(&1.name))
    |> MapSet.new()
  end
end
