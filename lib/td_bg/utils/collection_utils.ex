defmodule TdBg.Utils.CollectionUtils do
  @moduledoc false

  def to_struct(kind, attrs) do
    struct = struct(kind)

    struct
    |> Map.to_list()
    |> Enum.reduce(struct, fn {k, _}, acc ->
      case Map.fetch(attrs, Atom.to_string(k)) do
        {:ok, v} -> %{acc | k => v}
        :error -> acc
      end
    end)
  end

  def map_intersection(%{} = map1, %{} = map2) do
    keys1 = Map.keys(map1)
    keys2 = Map.keys(map2)

    keys = MapSet.intersection(MapSet.new(keys1), MapSet.new(keys2))
    map1 = Map.take(map1, MapSet.to_list(keys))
    map2 = Map.take(map2, MapSet.to_list(keys))

    Map.merge(map1, map2, fn _k, v1, v2 -> intersection(v1, v2) end)
  end

  def stringify_keys(%{} = map) do
    Map.new(map, fn {k, v} -> {stringify_key(k), v} end)
  end

  defp stringify_key(key) when is_atom(key), do: Atom.to_string(key)
  defp stringify_key(key), do: key

  def atomize_keys(%{} = map) do
    Map.new(map, fn {k, v} -> {atomize_key(k), v} end)
  end

  defp atomize_key(key) when is_binary(key), do: String.to_atom(key)
  defp atomize_key(key), do: key

  defp intersection(%MapSet{} = v1, %MapSet{} = v2) do
    MapSet.intersection(v1, v2)
  end

  defp intersection(_, _) do
    MapSet.new()
  end
end
