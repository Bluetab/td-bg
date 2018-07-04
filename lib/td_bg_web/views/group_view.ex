defmodule TdBgWeb.GroupView do
  use TdBgWeb, :view

  def render("group.json", %{group: group}) do
    %{id: group.id, name: group.name}
  end
end
