defmodule TdBg.Search.Query.Bool do
  @moduledoc """
  TODO
  """

  def add_should(%{} = query, clause), do: add_clause(query, :should, clause)
  def add_must(%{} = query, clause), do: add_clause(query, :must, clause)
  def add_must_not(%{} = query, clause), do: add_clause(query, :must_not, clause)

  def add_clause(%{} = query, key, clause) do
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
