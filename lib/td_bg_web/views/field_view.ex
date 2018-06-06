defmodule TdBgWeb.FieldView do
  use TdBgWeb, :view
  use TdBg.Hypermedia, :view

  alias TdBgWeb.FieldView

  def render("fields.json", %{fields: fields}) do
    %{data: render_many(fields, FieldView, "field.json")}
  end

  def render("field.json", %{field: field}) do
    %{
      system: field.system,
      group: field.group,
      structure: field.structure,
      name: field.name
    }
  end
end
