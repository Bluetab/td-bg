defmodule Mix.Tasks.Bg.EsClean do
  use Mix.Task
  alias TdBg.ESClientApi

  @moduledoc """
    Cleans ES indexes
  """

  def run(_args) do
    Mix.Task.run "app.start"

    ESClientApi.delete_indexes

  end
end
