defmodule TdBgWeb.ChangesetSupport do
  @moduledoc false
  alias Ecto.Changeset

  @cast "cast"
  @unique "unique"
  @code "undefined"

  def translate_errors(%Changeset{} = changeset) do
    Enum.reduce(changeset.errors, [], fn(error, acc) ->
      name_items = case changeset.data do
        %{__struct__: _} = data ->
          entity = data.__struct__
          |> Atom.to_string
          |> String.split(".")
          |> List.last
          |> String.downcase
          [entity]

        _ -> []
      end
      name_items = name_items ++
      ["error", Atom.to_string(elem(error, 0))] ++
      translate_error_desc(elem(error, 1))
      name = Enum.join(name_items, ".")
      acc ++ [%{code: @code, name: name}]
    end)
  end

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
