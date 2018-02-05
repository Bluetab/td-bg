defmodule TrueBGWeb.AclEntry do
  @moduledoc false

  alias Poison, as: JSON
  import TrueBGWeb.Router.Helpers
  import TrueBGWeb.Authentication, only: :functions
  @endpoint TrueBGWeb.Endpoint

  def acl_entry_create(token, acl_entry_params) do
    headers = get_header(token)
    body = %{acl_entry: acl_entry_params} |> JSON.encode!
    %HTTPoison.Response{status_code: status_code, body: resp} =
      HTTPoison.post!(acl_entry_url(@endpoint, :create), body, headers, [])
    {:ok, status_code, resp |> JSON.decode!}
  end

end
