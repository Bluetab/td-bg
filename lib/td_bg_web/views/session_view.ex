defmodule TdBgWeb.SessionView do
  use TdBgWeb, :view

  def render("show.json", %{token: token}) do
    %{token: token}
  end
end
