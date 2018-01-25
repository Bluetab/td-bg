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

  def change_password(conn, %{"new_password" => new_password,
                              "old_passord" => _old_passord}) do
    user = get_current_user(conn)
    with {:ok, %User{} = _user} <- Accounts.update_user(user, %{password: new_password}) do
      send_resp(conn, :ok, "")
    else
      _error ->
        send_resp(conn, :unprocessable_entity, "")
    end
  end

  defp check_password(user, password) do
    case user do
      nil -> Bcrypt.dummy_checkpw()
      _ -> Bcrypt.checkpw(password, user.password_hash)
    end
  end

end
