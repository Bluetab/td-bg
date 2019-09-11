defmodule TdBgWeb.LinkView do
  use TdBgWeb, :view
  use TdHypermedia, :view

  alias TdBgWeb.LinkView

  def render("index.json", %{hypermedia: hypermedia}) do
    render_many_hypermedia(hypermedia, LinkView, "show.json")
  end

  def render("embedded.json", %{link: link, hypermedia: hypermedia} = assigns) do
    render_one_hypermedia(
      link,
      hypermedia,
      LinkView,
      "embedded.json",
      Map.drop(assigns, [:link, :hypermedia])
    )
  end

  def render("embedded.json", %{link: link} = assigns) do
    render_one(
      link,
      LinkView,
      "link.json",
      Map.drop(assigns, [:link])
    )
  end

  def render("link.json", %{link: link}) do
    link
  end
end
