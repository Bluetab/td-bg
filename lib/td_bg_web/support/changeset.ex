defmodule TdBgWeb.ChangesetSupport do
  @moduledoc false
  alias Ecto.Changeset

  @cast "cast"
  @unique "unique"
  @code "undefined"
  @error "error"

  def translate_errors(changeset, prefix \\ nil)
  def translate_errors(%Changeset{} = changeset, nil) do
    translate_errors_with_prefix(changeset, [])
  end
  def translate_errors(%Changeset{} = changeset, prefix) do
    translate_errors_with_prefix(changeset, String.split(prefix, "."))
  end

  defp translate_errors_with_prefix(changeset, prefix) do
    prefix_items = get_actual_prefix(changeset, prefix)
    Enum.reduce(changeset.errors, [], fn(error, acc) ->
      name_items = prefix_items ++
      [Atom.to_string(elem(error, 0))] ++
      translate_error_desc(elem(error, 1))
      name = Enum.join(name_items, ".")
      acc ++ [%{code: @code, name: name}]
    end)
  end

  defp get_actual_prefix(changeset, []) do
    case changeset.data do
      %{__struct__: _} = data ->
        entity = data.__struct__
        |> Atom.to_string
        |> String.split(".")
        |> List.last
        |> String.replace(~r/.([A-Z])/, ".\\1")
        |> String.downcase
        [entity, @error]

      _ -> [@error]
    end

  end
  defp get_actual_prefix(_, prefix), do: prefix

  defp translate_error_desc({"has already been taken", []}), do: [@unique]
  defp translate_error_desc({_ , error}) do
    case Keyword.get(error, :validation) do
      :cast ->
        cast_type = error
        |> Keyword.get(:type)
        |> Atom.to_string
        [@cast, cast_type]
      validation -> [Atom.to_string(validation)]
    end
  end

end
