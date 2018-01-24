defmodule TrueBGWeb.SessionController do
  use TrueBGWeb, :controller

  alias Comeonin.Bcrypt
  alias TrueBG.Accounts
  alias TrueBG.Auth.Guardian.Plug, as: GuardianPlug
  alias TrueBGWeb.ErrorView

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
    conn
      |> GuardianPlug.sign_out()
      |> send_resp(:ok, "")
  end

  defp check_password(user, password) do
    case user do
      nil -> Bcrypt.dummy_checkpw()
      _ -> Bcrypt.checkpw(password, user.password_hash)
    end
  end

end
