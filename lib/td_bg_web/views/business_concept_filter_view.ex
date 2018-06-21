defmodule TdBgWeb.BusinessConceptFilterView do
  use TdBgWeb, :view

  def render("show.json", %{filters: filters}) do
    %{data: filters}
  end
end
