defmodule TdBg.Taxonomies.Domain do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset
  alias TdBg.ErrorConstantsSupport
  alias TdBg.Taxonomies
  alias TdBg.Taxonomies.Domain
  alias TdBg.Utils.CollectionUtils

  @errors ErrorConstantsSupport.taxonomy_support_errors()

  schema "domains" do
    field(:description, :string)
    field(:type, :string)
    field(:name, :string)
    field(:deleted_at, :utc_datetime_usec)
    belongs_to(:parent, Domain)

    timestamps(type: :utc_datetime_usec)
  end

  @doc false
  def changeset(%Domain{} = domain, attrs) do
    domain
    |> cast(attrs, [:name, :type, :description, :parent_id])
    |> validate_required([:name])
    |> validate_unique_name(domain)
  end

  def delete_changeset(%Domain{} = domain) do
    domain
    |> change(deleted_at: DateTime.utc_now())
    |> validate_domain_children()
    |> validate_existing_bc_children()
  end

  def to_struct(map) do
    map
    |> CollectionUtils.to_atom_pairs()
    |> Enum.reduce(%Domain{}, fn {k, v}, acc -> Map.put(acc, k, v) end)
  end

  defp validate_domain_children(changeset) do
    case changeset.valid? do
      true ->
        domain_id = changeset |> get_field(:id)
        {:count, :domain, count} = Taxonomies.count_domain_children(domain_id)

        case count > 0 do
          true ->
            domain_error = @errors.existing_child_domain
            add_error(changeset, :domain, domain_error.name, code: domain_error.code)

          false ->
            changeset
        end

      _ ->
        changeset
    end
  end

  defp validate_existing_bc_children(changeset) do
    case changeset.valid? do
      true ->
        domain_id = changeset |> get_field(:id)

        {:count, :business_concept, count} =
          Taxonomies.count_domain_business_concept_children(domain_id)

        case count > 0 do
          true ->
            domain_error = @errors.existing_child_business_concept
            add_error(changeset, :domain, domain_error.name, code: domain_error.code)

          false ->
            changeset
        end

      false ->
        changeset
    end
  end

  defp validate_unique_name(changeset, %Domain{id: domain_id}) do
    case changeset.valid? do
      true ->
        domain_name = changeset |> get_field(:name)
        {:count, :domain, count} = Taxonomies.count_domain_by_name(domain_name, domain_id)

        case count > 0 do
          true ->
            domain_error = @errors.existing_domain_with_same_name
            add_error(changeset, :domain, domain_error.name, code: domain_error.code)

          false ->
            changeset
        end

      false ->
        changeset
    end
  end
end
