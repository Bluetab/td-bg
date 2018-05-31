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

end
