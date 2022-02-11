defmodule TdBg.Search.Query do
  @moduledoc """
  TODO
  """

  def term_or_terms(field, value_or_values) do
    case List.wrap(value_or_values) do
      [value] -> %{term: %{field => value}}
      values -> %{terms: %{field => Enum.sort(values)}}
    end
  end
end
