defmodule TrueBGWeb.UserController do
  use TrueBGWeb, :controller

  alias TrueBG.Accounts
  alias TrueBG.Accounts.User
  alias Guardian.Plug

  alias TrueBGWeb.ErrorView
  action_fallback TrueBGWeb.FallbackController

  def index(conn, _params) do
    users = Accounts.list_users()
    render(conn, "index.json", users: users)
  end

  def create(conn, %{"user" => user_params}) do
    current_user = Plug.current_resource(conn)
    if current_user.is_admin do
      with {:ok, %User{} = user} <- Accounts.create_user(user_params) do
        conn
        |> put_status(:created)
        |> put_resp_header("location", user_path(conn, :show, user))
        |> render("show.json", user: user)

      else
        _error ->
          conn
            |> put_status(:unprocessable_entity)
            |> render(ErrorView, :"422.json")
      end
    else
      conn
      |> put_status(:unauthorized)
      |> render(ErrorView, :"401.json")
    end
  end

  def show(conn, %{"id" => id}) do
    user = Accounts.get_user!(id)
    render(conn, "show.json", user: user)
  end

  def update(conn, %{"id" => id, "user" => user_params}) do
    user = Accounts.get_user!(id)

    with {:ok, %User{} = user} <- Accounts.update_user(user, user_params) do
      render(conn, "show.json", user: user)
    end
  end

  def delete(conn, %{"id" => id}) do
    user = Accounts.get_user!(id)
    with {:ok, %User{}} <- Accounts.delete_user(user) do
      send_resp(conn, :no_content, "")
    end
  end
end
