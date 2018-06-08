defmodule TdBgWeb.ApiServices.MockTdDdService do
  @moduledoc false

  use Agent

  def start_link(_) do
    Agent.start_link(fn -> %{data_structures: [], data_fields: nil} end, name: MockTdDdService)
  end

  def set_data_structure(new_data_structure) do
    Agent.update(MockTdDdService, &Map.put(&1, :data_structures, [new_data_structure|&1.data_structures]))
  end

  def get_data_structures(%{} = _params) do
    Agent.get(MockTdDdService, &Map.get(&1, :data_structures))
  end

  def set_data_field(data_structure) do
    Agent.update(MockTdDdService, &Map.put(&1, :data_fields, data_structure))
  end

  def get_data_fields(%{} = _params) do
    Agent.get(MockTdDdService, &Map.get(&1, :data_fields))
  end

end
