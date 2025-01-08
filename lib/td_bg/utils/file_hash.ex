defmodule TdBg.Utils.Hasher do
  @moduledoc """
  File hash util
  """
  def hash_file(filepath, type \\ :md5) do
    filepath
    |> File.stream!(2048)
    |> Enum.reduce(
      :crypto.hash_init(type),
      fn line, acc -> :crypto.hash_update(acc, line) end
    )
    |> :crypto.hash_final()
    |> Base.encode16()
  end
end
