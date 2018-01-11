defmodule TrueBGWeb.TontoView do
  use TrueBGWeb, :view
  alias TrueBGWeb.TontoView

  def render("index.json", %{tontos: tontos}) do
    %{data: render_many(tontos, TontoView, "tonto.json")}
  end

  def render("show.json", %{tonto: tonto}) do
    %{data: render_one(tonto, TontoView, "tonto.json")}
  end

  def render("tonto.json", %{tonto: tonto}) do
    %{id: tonto.id}
  end
end
