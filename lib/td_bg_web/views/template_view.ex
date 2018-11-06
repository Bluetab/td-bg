defmodule TdBgWeb.TemplateView do
  use TdBgWeb, :view
  alias TdBgWeb.TemplateView

  def render("index.json", %{templates: templates}) do
    %{data: render_many(templates, TemplateView, "template.json")}
  end

  def render("template.json", %{template: template}) do
    %{
      id: template.id,
      label: template.label,
      name: template.name,
      content: template.content,
      is_default: Map.get(template, :is_default, false)
    }
  end
end
