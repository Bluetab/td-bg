defmodule TdBg.Auth.CurrentResource do
  @moduledoc """
  A plug to read the current session from Guardian and assign it to the :current_resource
  key in the connection.
  """

  use Plug.Builder
  alias Guardian.Plug, as: GuardianPlug

  plug(:current_resource)

  def init(opts), do: opts

  def current_resource(conn, _opts) do
    session = GuardianPlug.current_resource(conn)
    assign(conn, :current_resource, session)
  end
end
