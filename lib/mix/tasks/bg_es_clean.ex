defmodule Mix.Tasks.Bg.EsClean do
  use Mix.Task
  alias TdBg.Search

  @moduledoc """
    Cleans ES indexes
  """

  def run(_args) do
    Mix.Task.run "app.start"

    Search.delete_indexes

  end
end
