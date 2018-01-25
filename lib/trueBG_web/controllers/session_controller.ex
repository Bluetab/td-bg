defmodule TrueBGWeb.SessionController do
  use TrueBGWeb, :controller

  alias Comeonin.Bcrypt
  alias TrueBG.Accounts
  alias TrueBG.Accounts.User
  alias TrueBG.Auth.Guardian
  alias TrueBG.Auth.Guardian.Plug, as: GuardianPlug
  alias TrueBGWeb.ErrorView

  defp get_current_user(conn) do
    GuardianPlug.current_resource(conn)
  end

  defp handle_sign_in(conn, user) do
    conn
      |> GuardianPlug.sign_in(user)
  end

  def create(conn, %{"user" => %{"user_name" => user_name,
                     "password" => password}}) do
    user = Accounts.get_user_by_name(user_name)

    case check_password(user, password) do
      true ->
        conn = handle_sign_in(conn, user)
        token = GuardianPlug.current_token(conn)
        conn
          |> put_status(:created)
          |> render("show.json", token: token)
      _ ->
        conn
          |> put_status(:unauthorized)
          |> render(ErrorView, :"401.json")
    end
  end

  def ping(conn, _params) do
    conn
      |> send_resp(:ok, "")
  end

  def destroy(conn, _params) do
    token = GuardianPlug.current_token(conn)
    Guardian.revoke(token)
    send_resp(conn, :ok, "")
  end

  defp do_change_password(conn, user, new_password) do
    with {:ok, %User{} = _user} <- Accounts.update_user(user, %{password: new_password}) do
      send_resp(conn, :ok, "")
    else
      _error ->
        conn
          |> send_resp(:unprocessable_entity, "")
    end
  end

  def change_password(conn, %{"new_password" => new_password,
                              "old_passord" => old_password}) do
    user = get_current_user(conn)
    case check_password(user, old_password) do
      true ->
        conn
          |> do_change_password(user, new_password)
      _ ->
        conn
          |> send_resp(:unprocessable_entity, "")
    end
  end

  defp check_password(user, password) do
    case user do
      nil -> Bcrypt.dummy_checkpw()
      _ -> Bcrypt.checkpw(password, user.password_hash)
    end
  end

end
