defmodule TdBg.Auth.CurrentUser do
  @moduledoc """
  A plug to read the current user from Guardian and assign it to the :current_user
  key in the connection.
  """

  use Plug.Builder
  alias Guardian.Plug, as: GuardianPlug
  alias TdBg.Permissions

  plug(:current_user)
  plug(:preload_permission_cache)

  def init(opts), do: opts

  def current_user(conn, _opts) do
    current_user = GuardianPlug.current_resource(conn)

    conn |> assign(:current_user, current_user)
  end

  def preload_permission_cache(conn, _opts) do
    conn.assigns[:current_user]
      |> Permissions.get_or_store_session_permissions
    conn
  end

end
