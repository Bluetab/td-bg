defmodule TdBgWeb.TaxonomySupport do
  @moduledoc false
  require Logger
  use TdBgWeb, :controller
  alias TdBgWeb.ErrorView

  def handle_taxonomy_errors_on_delete(conn, error) do
    case error do
      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> put_view(TdBgWeb.ChangesetView)
        |> render("error.json", changeset: changeset)

      _error ->
        Logger.error("Unexpected error... #{inspect(error)}")

        conn
        |> put_status(:unprocessable_entity)
        |> put_view(ErrorView)
        |> render("422.json")
    end
  end
end
