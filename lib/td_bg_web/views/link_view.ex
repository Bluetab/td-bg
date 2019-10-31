defmodule TdBgWeb.LinkView do
  use TdBgWeb, :view

  alias TdBgWeb.LinkView

  def render("index.json", %{links: links}) do
    %{data: render_many(links, LinkView, "link.json")}
  end

  def render("embedded.json", %{link: link}) do
    render_one(
      link,
      LinkView,
     "link.json"
    )
  end

  def render("link.json", %{link: link}) do
    link
  end
end
