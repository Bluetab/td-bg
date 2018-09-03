defmodule TdBgWeb.ChangesetSupport do
  @moduledoc false
  alias Ecto.Changeset

  @cast "cast"
  @unique "unique"
  @code "undefined"
  @error "error"
  @msgids ["can't be blank",
           "is invalid",
           "must be accepted",
           "has invalid format",
           "has an invalid entry",
           "is reserved",
           "does not match confirmation",
           "is still associated with this entry",
           "are still associated with this entry",
           "should be %{count} character(s)",
           "should have %{count} item(s)",
           "should be at least %{count} character(s)",
           "should have at least %{count} item(s)",
           "should be at most %{count} character(s)",
           "should have at most %{count} item(s)",
           "should have at most %{count} item(s)",
           "must be less than %{number}",
           "must be greater than %{number}",
           "must be less than or equal to %{number}",
           "must be greater than or equal to %{number}",
           "must be equal to %{number}"]

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
      translate_msgid(elem(error, 1))
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

  defp translate_msgid({"has already been taken", []}), do: [@unique]
  defp translate_msgid({msgid , desc}) when msgid in @msgids do
    case Keyword.get(desc, :validation) do
      :cast ->
        cast_type = desc
        |> Keyword.get(:type)
        |> Atom.to_string
        [@cast, cast_type]
      validation -> [Atom.to_string(validation)]
    end
  end
  defp translate_msgid({msgid, _}), do: String.split(msgid, ".")

end
