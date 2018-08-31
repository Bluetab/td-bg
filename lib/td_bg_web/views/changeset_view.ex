defmodule TdBgWeb.ChangesetView do
  use TdBgWeb, :view
  import TdBgWeb.ChangesetSupport

  def render("error.json", %{changeset: changeset}) do
    %{errors: translate_errors(changeset)}
  end
end
