defmodule TrueBGWeb.SessionView do
  use TrueBGWeb, :view

  def render("show.json", %{token: token}) do
    %{token: token}
  end

end
