defmodule Mix.Tasks.Td.CodeAnalysis do
  use Mix.Task
  alias Mix.Tasks.Credo

  @shortdoc "Run code analysis"

  @moduledoc """
    Run code analysis.
  """

  def run(_args) do
    Credo.run(["--strict"])
  end

end
