defmodule TdBg.ResultSteps do
  @moduledoc false
  use Cabbage.Feature
  use ExUnit.CaseTemplate

  defthen ~r/^the system returns a result with code "(?<status_code>[^"]+)"$/,
          %{status_code: status_code}, %{status_code: http_status_code} = state do
    assert status_code == to_response_code(http_status_code)
    {:ok, state}
  end

  defthen ~r/^if (?<user_name>[^"]+) is "(?<target_user_name>[^"]+)" the system returns following data:$/,
    %{user_name: user_name, target_user_name: target_user_name, table: fields},
    %{business_concept_versions: business_concept_versions} = _state do
    if user_name == target_user_name do

      field_atoms = [:name, :type, :description, :version, :status]
      cooked_versions = business_concept_versions
      |> Enum.reduce([], &([map_keys_to_atoms_refactor(&1)| &2]))
      |> Enum.map(&(Map.take(&1, field_atoms)))
      |> Enum.sort

      cooked_fields = fields
      |> Enum.reduce([], &([update_business_concept_version_map_refactor(&1)|&2]))
      |> Enum.map(&(Map.take(&1, field_atoms)))
      |> Enum.sort

      assert cooked_versions == cooked_fields
    end
  end

  #We have to refactor this when importing steps functionallity works properly
  def map_keys_to_atoms_refactor(version), do: Map.new(version, &({String.to_atom(elem(&1, 0)), elem(&1, 1)}))

  def update_business_concept_version_map_refactor(field_map), do: update_in(field_map[:version], &String.to_integer(&1))

end
