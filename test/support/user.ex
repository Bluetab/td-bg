defmodule TdBgWeb.User do
  @moduledoc false

  def get_role_by_name(role_name) do
    # Use hash to map name to role id for tests
    id = hash_to_int(role_name)
    %{id: id, name: role_name}
  end

  defp hash_to_int(s) do
    s
    |> (&:crypto.hash(:sha, &1)).()
    |> :binary.bin_to_list()
    |> Enum.sum()
  end
end
