defmodule TdBg.Taxonomies.Domain do
  @moduledoc """
  Ecto schema representing a domain in the business glossary.
  """

  require Logger

  use Ecto.Schema

  import Ecto.Changeset

  alias Ecto.Changeset
  alias TdBg.BusinessConcepts
  alias TdBg.BusinessConcepts.BusinessConcept
  alias TdBg.Groups.DomainGroup
  alias TdBg.Taxonomies
  alias TdCore.Utils.CollectionUtils

  schema "domains" do
    field(:description, :string)
    field(:type, :string)
    field(:name, :string)
    field(:external_id, :string)
    field(:deleted_at, :utc_datetime_usec)
    field(:parents, {:array, :map}, virtual: true)
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
    |> validate_required([:name, :external_id])
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
           domain_group: nil,
           descendents: descendents
         },
         %__MODULE__{id: id}
       ) do
    changeset = valid_group(changeset, id, nil, descendents)
    put_group(changeset, %{domain_group: nil})
  end

  defp put_group(
         %Changeset{valid?: true} = changeset,
         %{
           domain_group: %DomainGroup{} = domain_group,
           descendents: descendents
         },
         %__MODULE__{id: id}
       ) do
    changeset = valid_group(changeset, id, domain_group, descendents)
    put_group(changeset, %{domain_group: domain_group})
  end

  defp put_group(
         %Changeset{valid?: true} = changeset,
         %{
           domain_group: nil
         },
         _domain
       ) do
    put_group(changeset, %{domain_group: nil})
  end

  defp put_group(
         %Changeset{valid?: true} = changeset,
         %{
           domain_group: %DomainGroup{} = domain_group
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

  defp valid_group(changeset, domain_id, domain_group, descendents) do
    group_id = Map.get(domain_group || %{}, :id)
    descendant_ids = [domain_id | Enum.map(descendents, & &1.id)]
    validate_concept_names(changeset, group_id, descendant_ids)
  end

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
    from_group =
      group_id
      |> BusinessConcepts.get_active_concepts_in_group()
      |> grouped_by_type()

    from_descendants =
      domain_ids
      |> BusinessConcepts.get_active_concepts_by_domain_ids()
      |> grouped_by_type()

    changeset
    |> validate_intersection(from_descendants)
    |> validate_intersection(CollectionUtils.merge_common(from_group, from_descendants))
  end

  defp grouped_by_type(collection) do
    collection
    |> Enum.group_by(&(&1 |> Map.get(:business_concept) |> Map.get(:type)))
    |> Enum.map(fn {k, v} -> {k, Enum.map(v, &String.downcase(&1.name))} end)
    |> Enum.into(%{})
  end

  defp validate_intersection(%Ecto.Changeset{valid?: false} = changeset, _names_by_type),
    do: changeset

  defp validate_intersection(changeset, names_by_type) do
    names_by_type
    |> Enum.map(fn {_k, names} -> Enum.frequencies_by(names, &String.downcase/1) end)
    |> Enum.map(&Enum.to_list/1)
    |> List.flatten()
    |> Enum.find(fn {_name, count} -> count > 1 end)
    |> case do
      nil ->
        changeset

      {name, _count} ->
        Logger.info("Concept #{name} duplicated")
        add_error(changeset, :business_concept, "domain.error.existing.business_concept.name")
    end
  end
end
