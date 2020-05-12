defmodule TdBgWeb.ChangesetView do
  use TdBgWeb, :view

  alias Ecto.Changeset
  alias TdBgWeb.ChangesetSupport

  def render("error.json", %{changeset: changeset, prefix: prefix}) do
    %{errors: ChangesetSupport.translate_errors(changeset, prefix)}
  end

  def render("error.json", %{changeset: changeset}) do
    %{errors: translate_errors(changeset)}
  end

  defp translate_errors(changeset) do
    Changeset.traverse_errors(changeset, &translate_error/1)
  end
end
