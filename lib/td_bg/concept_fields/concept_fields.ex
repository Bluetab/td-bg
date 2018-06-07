defmodule TdBg.ConceptFields do
  @moduledoc """
  The ConceptFields context.
  """

  import Ecto.Query, warn: false
  alias ValidationError
  alias TdBg.Repo
  alias TdBg.ConceptFields.ConceptField

  def list_concept_fields(concept) do
    Repo.all(from(r in ConceptField,
      where: r.concept == ^concept))
  end

  def get_concept_field(id) do
    Repo.one(from(r in ConceptField,
      where: r.id == ^id))
  end

  def get_concept_field!(id) do
    Repo.one!(from(r in ConceptField,
      where: r.id == ^id))
  end

  def create_concept_field(attrs \\ %{}) do
    %ConceptField{}
    |> ConceptField.changeset(attrs)
    |> Repo.insert()
  end

  def delete_concept_field(%ConceptField{} = concept_field) do
    Repo.delete(concept_field)
  end

end
