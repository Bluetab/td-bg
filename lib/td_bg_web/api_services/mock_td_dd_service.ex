defmodule TdBgWeb.ApiServices.MockTdDdService do
  @moduledoc false

  use Agent

  def start_link(_) do
    Agent.start_link(fn -> [] end, name: MockTdDdService)
  end

  def set_data_structure(new_data_structure) do
    Agent.update(MockTdDdService, &(&1 ++ [new_data_structure]))
  end

  def get_data_structures(%{} = _params) do
    Agent.get(MockTdDdService, &(&1))
  end

  def set_data_fields(_new_data_field) do
    # Implement this
  end

  def get_data_fields(%{} = _params) do
    # Implement this
  end

  def get_data_structure(%{} = _params) do
    # Implement this
  end

  def get_data_field(%{} = _params) do
    # Implement this    
  end

end
