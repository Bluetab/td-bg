defmodule TdBgWeb.DataStructureView do
  use TdBgWeb, :view
  use TdBg.Hypermedia, :view

  alias TdBgWeb.DataStructureView

  def render("data_structures.json", %{data_structures: data_structures}) do
    %{data: render_many(data_structures, DataStructureView, "data_structure.json")}
  end

  def render("data_structure.json", %{data_structure: data_structure}) do
    %{id: data_structure.id,
      ou: data_structure.ou,
      system: data_structure.system,
      group: data_structure.group,
      name: data_structure.name}
  end

end
