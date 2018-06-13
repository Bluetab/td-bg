defmodule TdBgWeb.TaxonomySupport do
  @moduledoc false
  require Logger
  use TdBgWeb, :controller
  alias TdBgWeb.ErrorView

  def handle_taxonomy_errors_on_delete(conn, error) do
    case error do
      {:count, :domain, n} when is_integer(n) ->
          conn
          |> put_status(:unprocessable_entity)
          |> json(%{"errors": %{domain: ["existing_child_domain"]}})
      {:count, :business_concept, n} when is_integer(n) ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{"errors": %{business_concept: ["existing_child_business_concept"]}})
      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(TdBgWeb.ChangesetView, "error.json", changeset: changeset)
      _error ->
        Logger.error("Unexpected error... #{inspect(error)}")
        conn
        |> put_status(:unprocessable_entity)
        |> render(ErrorView, :"422.json")
    end
  end
end
