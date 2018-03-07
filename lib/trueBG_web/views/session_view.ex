defmodule TdBGWeb.SessionView do
  use TdBGWeb, :view

  def render("show.json", %{token: token}) do
    %{token: token}
  end

end
