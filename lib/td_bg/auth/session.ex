defmodule TdBg.Auth.Session do
  @moduledoc "A user session"

  @derive {Jason.Encoder, only: [:user_id, :user_name]}
  defstruct [:user_id, :user_name, :is_admin, :role, :jti]
end
