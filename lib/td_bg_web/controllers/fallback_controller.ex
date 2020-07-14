defmodule TdBgWeb.FallbackController do
  @moduledoc """
  Translates controller action results into valid `Plug.Conn` responses.

  See `Phoenix.Controller.action_fallback/1` for more details.
  """
  use TdBgWeb, :controller

  alias Jason, as: JSON

  def call(conn, {:error, %Ecto.Changeset{} = changeset}) do
    conn
    |> put_status(:unprocessable_entity)
    |> put_view(TdBgWeb.ChangesetView)
    |> render("error.json", changeset: changeset)
  end

  def call(conn, {:error, _field, %Ecto.Changeset{} = changeset, _changes_so_far}) do
    call(conn, {:error, changeset})
  end

  def call(conn, {:error, :not_found}) do
    conn
    |> put_status(:not_found)
    |> put_view(TdBgWeb.ErrorView)
    |> render("404.json")
  end

  def call(conn, {:error, error}) do
    conn
    |> put_resp_content_type("application/json", "utf-8")
    |> send_resp(:unprocessable_entity, JSON.encode!(%{error: error}))
  end

  def call(conn, {:can, false}) do
    conn
    |> put_status(:forbidden)
    |> put_view(TdBgWeb.ErrorView)
    |> render("403.json")
  end
end
