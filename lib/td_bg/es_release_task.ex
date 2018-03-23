defmodule TdBg.EsReleaseTask do
  @moduledoc false
  alias TdBg.ESClientApi

  def init_es do
    # Load the code for TdBg, but don't start it
    :ok = Application.load(:td_bg)

    ESClientApi.create_indexes
  end
end
