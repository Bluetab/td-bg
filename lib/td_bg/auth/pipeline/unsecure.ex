defmodule TdBg.Auth.Pipeline.Unsecure do
  @moduledoc false
  use Guardian.Plug.Pipeline,
    otp_app: :td_bg,
    error_handler: TdBg.Auth.ErrorHandler,
    module: TdBg.Auth.Guardian

  plug Guardian.Plug.VerifyHeader
  plug Guardian.Plug.LoadResource, allow_blank: true
end
