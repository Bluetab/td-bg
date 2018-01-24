defmodule TrueBGWeb.ResponseCode do
  @moduledoc false

  def to_response_code(http_status_code) do
    case http_status_code do
      200 -> "Ok"
      201 -> "Created"
      401 -> "Forbidden"
      404 -> "NotFound"
      422 -> "Unprocessable Entity"
      _ -> "Unknown"
    end
  end

end
