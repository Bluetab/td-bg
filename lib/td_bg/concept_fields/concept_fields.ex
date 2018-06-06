defmodule TdBg.ConceptFields do
  @moduledoc """
  The ConceptFields context.
  """

  import Ecto.Query, warn: false
  alias ValidationError
  alias Ecto.Multi
  alias Ecto.Changeset
  alias TdBg.Repo
  alias TdBg.ConceptFields.ConceptField

  def list_concept_fields(concept) do
    Repo.all(from(r in ConceptField,
      where: r.concept == ^concept))
  end

  def get_concept_field(concept, field) do
    Repo.one(from(r in ConceptField,
      where: r.concept == ^concept and
             r.field == ^field))
  end

  def get_concept_field!(concept, field) do
    Repo.one!(from(r in ConceptField,
      where: r.concept == ^concept and
             r.field == ^field))
  end

  def create_concept_field(attrs \\ %{}) do
    case create_delete_concept_fields([attrs], []) do
      {:ok, %{create_0: %ConceptField{} = concept_field}} ->
          {:ok, concept_field}
      {:error, %{create_0: %Changeset{} = changeset}} -> {:error, changeset}
    end
  end

  def delete_concept_field(%ConceptField{} = concept_field) do
    case create_delete_concept_fields([], [concept_field]) do
      {:ok, %{delete_0: %ConceptField{} = concept_field}} ->
          {:ok, concept_field}
      {:error, %{delete_0: %Changeset{} = changeset}} -> {:error, changeset}
    end
  end

#  def create_delete_concept_fields([], []), do: {:ok, %{}}
  def create_delete_concept_fields(to_create, to_delete) do
    Multi.new()
    |> create_concept_fields(0, to_create)
    |> delete_concept_fields(0, to_delete)
    |> Repo.transaction()
  end

  def load_concept_fields(concept, fields) do
    old_fields = list_concept_fields(concept)

    to_create = fields
    |> Enum.filter(fn(n) ->
        Enum.find(old_fields, fn(o) ->
          n == o.field
        end) == nil
       end)
    |> Enum.map(&(%{concept: concept, field: &1}))

    to_delete = Enum.filter(old_fields, fn(o) ->
      Enum.find(fields, fn(n) ->
        n == o.field
      end) == nil
    end)

    result = case create_delete_concept_fields(to_create, to_delete) do
      {:ok, _} -> :ok_loading_fields
      _ -> :error_loadind_fields
    end

    current_fields = list_concept_fields(concept)
    {result, Enum.map(current_fields, &Map.get(&1, :field))}
  end

  defp create_concept_fields(multi, _l, []), do: multi
  defp create_concept_fields(multi, l, [head|tail]) do
    multi
    |> create_concept_fields(l, head)
    |> create_concept_fields(l + 1, tail)
  end
  defp create_concept_fields(multi, l, attrs) do
    Multi.insert(multi, String.to_atom("create_#{l}"),
      ConceptField.changeset(%ConceptField{}, attrs))
  end

  defp delete_concept_fields(multi, _l, []), do: multi
  defp delete_concept_fields(multi, l, [head|tail]) do
    multi
    |> delete_concept_fields(l, head)
    |> delete_concept_fields(l + 1, tail)
  end
  defp delete_concept_fields(multi, l, concept_field) do
    Multi.delete(multi, String.to_atom("delete_#{l}"),
      concept_field)
  end

end
