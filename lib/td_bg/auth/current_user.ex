defmodule TdBg.Auth.CurrentUser do
  @moduledoc """
  A plug to read the current user from Guardian and assign it to the :current_user
  key in the connection.
  """

  use Plug.Builder
  alias Guardian.Plug, as: GuardianPlug

  plug(:current_user, key: :current_user)

  def init(opts), do: opts

  def current_user(conn, opts) do
    current_user = GuardianPlug.current_resource(conn)
    conn |> assign(opts[:key], current_user)
  end
end
