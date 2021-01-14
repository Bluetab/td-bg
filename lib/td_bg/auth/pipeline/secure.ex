defmodule TdBg.Auth.Pipeline.Secure do
  @moduledoc false
  use Guardian.Plug.Pipeline,
    otp_app: :td_bg,
    error_handler: TdBg.Auth.ErrorHandler,
    module: TdBg.Auth.Guardian

  plug Guardian.Plug.EnsureAuthenticated, claims: %{"typ" => "access"}

  # Assign :current_resource to connection
  plug TdBg.Auth.CurrentResource
end
