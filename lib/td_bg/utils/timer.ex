defmodule Timer do
  @moduledoc """
  Utility for timing function invocations
  """

  def time(fun, on_complete, unit \\ :millis)

  def time(fun, on_complete, :millis), do: do_time(fun, on_complete, 1_000)

  def time(fun, on_complete, :seconds), do: do_time(fun, on_complete, 1_000_000)

  def binary_to_utc_date_time(time) do
    {:ok, time} = NaiveDateTime.from_iso8601(time)
    {:ok, time} = DateTime.from_naive(time, "Etc/UTC")
    time
  end

  defp do_time(fun, on_complete, divisor) do
    {micros, res} = :timer.tc(fun)

    try do
      micros
      |> div(divisor)
      |> on_complete.(res)

      res
    rescue
      _ -> res
    end
  end
end
