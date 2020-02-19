defmodule TdBg.Taxonomies.Domain do
  @moduledoc """
  Ecto schema representing a domain in the business glossary.
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias Ecto.Changeset
  alias TdBg.ErrorConstantsSupport
  alias TdBg.Taxonomies
  alias TdBg.Taxonomies.Domain

  @errors ErrorConstantsSupport.taxonomy_support_errors()

  schema "domains" do
    field(:description, :string)
    field(:type, :string)
    field(:name, :string)
    field(:external_id, :string)
    field(:deleted_at, :utc_datetime_usec)
    belongs_to(:parent, Domain)

    timestamps(type: :utc_datetime_usec)
  end

  @doc false
  def changeset(%Domain{} = domain, attrs) do
    domain
    |> cast(attrs, [:name, :type, :description, :parent_id, :external_id])
    |> validate_required([:name])
    |> validate_unique(domain, [:name, :external_id])
  end

  def delete_changeset(%Domain{} = domain) do
    domain
    |> change(deleted_at: DateTime.utc_now())
    |> validate_domain_children()
    |> validate_existing_bc_children()
  end

  defp validate_domain_children(changeset) do
    case changeset.valid? do
      true ->
        domain_id = changeset |> get_field(:id)
        {:count, :domain, count} = Taxonomies.count_domain_children(domain_id)

        case count > 0 do
          true ->
            domain_error = @errors[:integrity_constraint][:domain]
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
            domain_error = @errors[:integrity_constraint][:business_concept]
            add_error(changeset, :domain, domain_error.name, code: domain_error.code)

          false ->
            changeset
        end

      false ->
        changeset
    end
  end

  defp validate_unique(%Changeset{valid?: false} = changeset, _domain, _fields), do: changeset

  defp validate_unique(%Changeset{valid?: true} = changeset, domain, fields) do
    field_uniqueness(changeset, domain, fields)
  end

  defp field_uniqueness(changeset, _domain, []), do: changeset

  defp field_uniqueness(changeset, %Domain{id: domain_id} = domain, [field | tail]) do
    value = get_field(changeset, field)

    case not unique_field?(field, value, domain_id) do
      true ->
        error = @errors[:uniqueness][field]
        add_error(changeset, :domain, error.name, code: error.code)

      false ->
        field_uniqueness(changeset, domain, tail)
    end
  end

  defp unique_field?(_field, nil, _domain_id), do: true

  defp unique_field?(field, value, domain_id),
    do: Taxonomies.count_by(field, value, domain_id) == 0
end
