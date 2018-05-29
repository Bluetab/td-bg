defmodule TdBg.BusinessConceptDataFields do
  @moduledoc """
  The BusinessConceptDataFields context.
  """

  import Ecto.Query, warn: false
  alias ValidationError
  alias Ecto.Multi
  alias Ecto.Changeset
  alias TdBg.Repo
  alias TdBg.BusinessConceptDataFields.BusinessConceptDataField

  def list_business_concept_data_fields(business_concept) do
    Repo.all(from(r in BusinessConceptDataField,
      where: r.business_concept == ^business_concept))
  end

  def get_business_concept_data_field(business_concept, data_field) do
    Repo.one(from(r in BusinessConceptDataField,
      where: r.business_concept == ^business_concept and
             r.data_field == ^data_field))
  end

  def get_business_concept_data_field!(business_concept, data_field) do
    Repo.one!(from(r in BusinessConceptDataField,
      where: r.business_concept == ^business_concept and
             r.data_field == ^data_field))
  end

  def create_business_concept_data_field(attrs \\ %{}) do
    case create_delete_business_concept_data_fields([attrs], []) do
      {:ok, %{create_0: %BusinessConceptDataField{} = business_concept_data_field}} ->
          {:ok, business_concept_data_field}
      {:error, %{create_0: %Changeset{} = changeset}} -> {:error, changeset}
    end
  end

  def delete_business_concept_data_field(%BusinessConceptDataField{} = business_concept_data_field) do
    case create_delete_business_concept_data_fields([], [business_concept_data_field]) do
      {:ok, %{delete_0: %BusinessConceptDataField{} = business_concept_data_field}} ->
          {:ok, business_concept_data_field}
      {:error, %{delete_0: %Changeset{} = changeset}} -> {:error, changeset}
    end
  end

#  def create_delete_business_concept_data_fields([], []), do: {:ok, %{}}
  def create_delete_business_concept_data_fields(to_create, to_delete) do
    Multi.new()
    |> create_business_concept_data_fields(0, to_create)
    |> delete_business_concept_data_fields(0, to_delete)
    |> Repo.transaction()
  end

  def load_business_concept_data_fields(business_concept, data_fields) do
    old_data_fields = list_business_concept_data_fields(business_concept)

    to_create = data_fields
    |> Enum.filter(fn(n) ->
        Enum.find(old_data_fields, fn(o) ->
          n == o.data_field
        end) == nil
       end)
    |> Enum.map(&(%{business_concept: business_concept, data_field: &1}))

    to_delete = Enum.filter(old_data_fields, fn(o) ->
      Enum.find(data_fields, fn(n) ->
        n == o.data_field
      end) == nil
    end)

    result = case create_delete_business_concept_data_fields(to_create, to_delete) do
      {:ok, _} -> :ok_loading_data_fields
      _ -> :error_loadind_data_fields
    end

    current_data_fields = list_business_concept_data_fields(business_concept)
    {result, Enum.map(current_data_fields, &Map.get(&1, :data_field))}
  end

  defp create_business_concept_data_fields(multi, _l, []), do: multi
  defp create_business_concept_data_fields(multi, l, [head|tail]) do
    multi
    |> create_business_concept_data_fields(l, head)
    |> create_business_concept_data_fields(l + 1, tail)
  end
  defp create_business_concept_data_fields(multi, l, attrs) do
    Multi.insert(multi, String.to_atom("create_#{l}"),
      BusinessConceptDataField.changeset(%BusinessConceptDataField{}, attrs))
  end

  defp delete_business_concept_data_fields(multi, _l, []), do: multi
  defp delete_business_concept_data_fields(multi, l, [head|tail]) do
    multi
    |> delete_business_concept_data_fields(l, head)
    |> delete_business_concept_data_fields(l + 1, tail)
  end
  defp delete_business_concept_data_fields(multi, l, business_concept_data_field) do
    Multi.delete(multi, String.to_atom("delete_#{l}"),
      business_concept_data_field)
  end

end
