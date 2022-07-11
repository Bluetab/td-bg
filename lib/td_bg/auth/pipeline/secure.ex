defmodule TdBg.Auth.Pipeline.Secure do
  @moduledoc """
  Plug pipeline for routes requiring authentication
  """

  use Guardian.Plug.Pipeline,
    otp_app: :td_bg,
    error_handler: TdBg.Auth.ErrorHandler,
    module: TdBg.Auth.Guardian

  plug Guardian.Plug.EnsureAuthenticated, claims: %{"aud" => "truedat", "iss" => "tdauth"}
  plug Guardian.Plug.LoadResource
  plug TdBg.Auth.Plug.SessionExists
  plug TdBg.Auth.Plug.CurrentResource
end
