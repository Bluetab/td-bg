defmodule TrueBGWeb.SessionController do
  use TrueBGWeb, :controller

  alias TrueBG.Accounts
  alias TrueBG.Guardian.Plug, as: GuardianPlug
  alias Poison, as: JSON

  # def create(conn, %{"user" => params}) do
  #   changeset = User.registration_changeset(%User{}, params)
  #   handle_sign_in(conn, changeset)
  # end
  #

  defp handle_sign_in(conn, user) do
    conn
    |> GuardianPlug.sign_in(user, %{})
    |> put_status(:created)
    token = GuardianPlug.current_token(conn)

    token
  end

  def create(conn, %{"user" => %{"user_name" => user_name, "password" => password}}) do
    user = Accounts.get_user_by_name(user_name)

    case check_password(user, password) do
      true ->
        token = handle_sign_in(conn, user)
        resp = %{token: ''} |> JSON.encode!
        send_resp(conn, 201, resp)

      _ -> send_resp(conn, 401, "Invalid credentials")
    end
  end

  defp check_password(user, password) do
    IO.inspect(user)
    IO.inspect(password)
    # case user do
    #   nil -> Comeonin.Bcrypt.dummy_checkpw()
    #   _ -> Comeonin.Bcrypt.checkpw(password, user.password_hash)
    # end
    Comeonin.Bcrypt.checkpw(password, user.password_hash)
  end

end
