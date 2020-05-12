defmodule TdBg.Taxonomies.Domain do
  @moduledoc """
  Ecto schema representing a domain in the business glossary.
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias TdBg.Taxonomies

  schema "domains" do
    field(:description, :string)
    field(:type, :string)
    field(:name, :string)
    field(:external_id, :string)
    field(:deleted_at, :utc_datetime_usec)
    belongs_to(:parent, __MODULE__)

    timestamps(type: :utc_datetime_usec)
  end

  def changeset(%{} = params) do
    changeset(%__MODULE__{}, params)
  end

  def changeset(%__MODULE__{} = domain, attrs) do
    domain
    |> cast(attrs, [:name, :type, :description, :parent_id, :external_id])
    |> validate_required([:name])
    |> unique_constraint(:external_id)
    |> unique_constraint(:name)
    |> validate_parent_id(domain)
    |> foreign_key_constraint(:parent_id, name: :domains_parent_id_fkey)
  end

  def delete_changeset(%__MODULE__{} = domain) do
    change(domain, deleted_at: DateTime.utc_now())
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
end
