defmodule TdBg.Hypermedia do
@moduledoc """
"""
  def controller do
    quote do
      import TdBgWeb.Hypermedia.HypermediaControllerHelper
    end
  end

  def view do
    quote do
      import TdBgWeb.Hypermedia.HypermediaViewHelper
    end
  end

  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end

end
