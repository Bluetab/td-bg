defmodule Mix.Tasks.Bg.Migrate do
  use Mix.Task
  alias TdBg.ReleaseTasks
  @moduledoc """
    Run
  """

  def run(_args) do
    ReleaseTasks.seed()
  end
end
