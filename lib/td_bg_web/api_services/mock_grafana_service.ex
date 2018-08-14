defmodule TdBgWeb.ApiServices.MockGrafanaService do
  @moduledoc false

  def create_panels(_id) do
  end
  def delete_panel(_id) do
  end
  def get_dashboard(_id) do
    {:error, nil}
  end

end
