defmodule TdBgWeb.BusinessConceptSupport do
  require Logger
  use TdBgWeb, :controller
  alias TdBgWeb.ErrorView
  @moduledoc false
  def handle_bc_errors(conn, error) do
    case error do
      false ->
        conn
        |> put_status(:forbidden)
        |> render(ErrorView, :"403.json")
      {:name_not_available} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{"errors": %{name: ["unique"]}})
      {:not_valid_related_to} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{"errors": %{related_to: ["invalid"]}})
      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(TdBgWeb.ChangesetView, "error.json", changeset: changeset)
      error ->
        Logger.error("Business concept... #{inspect(error)}")
        conn
        |> put_status(:unprocessable_entity)
        |> render(ErrorView, :"422.json")
    end
  end
end
