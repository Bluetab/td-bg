defmodule TdBg.Search.Query do
  @moduledoc """
  Support for composing search queries
  """

  def term(field, value_or_values) do
    case List.wrap(value_or_values) do
      [value] -> %{term: %{field => value}}
      values -> %{terms: %{field => Enum.sort(values)}}
    end
  end

  def should(%{} = query, clause), do: put_clause(query, :should, clause)
  def must(%{} = query, clause), do: put_clause(query, :must, clause)
  def must_not(%{} = query, clause), do: put_clause(query, :must_not, clause)

  def put_clause(%{} = query, key, clause) do
    Map.update(query, key, [clause], &[clause | &1])
  end

  def bool_query(%{} = clauses) do
    bool =
      clauses
      |> Map.take([:filter, :must, :should, :must_not, :minimum_should_match, :boost])
      |> Map.new(fn
        {key, [value]} when key in [:filter, :must, :must_not, :should] -> {key, value}
        {key, value} -> {key, value}
      end)

    %{bool: bool}
  end
end
