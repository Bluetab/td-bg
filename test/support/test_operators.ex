defmodule TdBg.TestOperators do
  @moduledoc """
  Equality operators for tests
  """

  def a <~> b, do: approximately_equal(a, b)
  def a ||| b, do: approximately_equal(Enum.sort(a), Enum.sort(b))

  defp approximately_equal([h1 | t1], [h2 | t2]) do
    approximately_equal(h1, h2) && approximately_equal(t1, t2)
  end

  defp approximately_equal(a, b), do: a == b
end
