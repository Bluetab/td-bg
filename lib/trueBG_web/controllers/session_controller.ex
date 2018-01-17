defmodule TrueBGWeb.SessionController do
  use TrueBGWeb, :controller

  alias Comeonin.Bcrypt
  alias TrueBG.Accounts
  alias TrueBG.Auth.Guardian.Plug, as: GuardianPlug
  alias Poison, as: JSON

  # def create(conn, %{"user" => params}) do
  #   changeset = User.registration_changeset(%User{}, params)
  #   handle_sign_in(conn, changeset)
  # end
  #

  defp handle_sign_in(conn, user) do
    conn
      |> GuardianPlug.sign_in(user)
      |> put_status(:created)
      |> GuardianPlug.current_token
  end

  def create(conn, %{"user" => %{"user_name" => user_name,
                     "password" => password}}) do
    user = Accounts.get_user_by_name(user_name)

    case check_password(user, password) do
      true ->
        token = handle_sign_in(conn, user)
        resp = %{token: token} |> JSON.encode!
        send_resp(conn, 201, resp)
      _ -> send_resp(conn, 401, %{msg: "Invalid credentials"} |> JSON.encode!)
    end
  end

  defp check_password(user, password) do
    case user do
      nil -> Bcrypt.dummy_checkpw()
      _ -> Bcrypt.checkpw(password, user.password_hash)
    end
  end

end
