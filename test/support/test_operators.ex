defmodule TdBg.TestOperators do
  @moduledoc """
  Equality operators for tests
  """

  def a <~> b, do: approximately_equal(a, b)
  def a ||| b, do: approximately_equal(sorted(a), sorted(b))

  ## Sort by id if present
  defp sorted([%{id: _} | _] = list) do
    Enum.sort_by(list, & &1.id)
  end

  defp sorted(list), do: Enum.sort(list)

  defp approximately_equal([h1 | t1], [h2 | t2]) do
    approximately_equal(h1, h2) && approximately_equal(t1, t2)
  end

  defp approximately_equal(a, b), do: a == b
end
