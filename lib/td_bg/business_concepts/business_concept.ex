defmodule TdBg.BusinessConcepts.BusinessConcept do
  @moduledoc """
  Ecto Schema module for Business Concepts.
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias TdBg.BusinessConcepts.BusinessConceptVersion
  alias TdBg.SharedConcepts.SharedConcept
  alias TdBg.Taxonomies.Domain

  schema "business_concepts" do
    belongs_to(:domain, Domain)
    field(:confidential, :boolean)
    field(:type, :string)
    field(:last_change_by, :integer)
    field(:last_change_at, :utc_datetime_usec)
    field(:subscribable_fields, {:array, :string}, virtual: true)
    field(:domain_ids, {:array, :integer}, virtual: true)

    has_many(:versions, BusinessConceptVersion)

    many_to_many(:shared_to, Domain,
      join_through: SharedConcept,
      on_replace: :delete,
      on_delete: :delete_all
    )

    timestamps(type: :utc_datetime_usec)
  end

  def changeset(%__MODULE__{} = business_concept, attrs) do
    business_concept
    |> cast(attrs, [:confidential, :domain_id, :type, :last_change_by, :last_change_at])
    |> validate_required([:domain_id, :type, :last_change_by, :last_change_at])
    |> put_shared_domains(attrs)
  end

  defp put_shared_domains(%{valid?: true} = changeset, %{shared_to: shared_to}) do
    put_assoc(changeset, :shared_to, shared_to)
  end

  defp put_shared_domains(changeset, _params), do: changeset
end
