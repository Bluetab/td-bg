defmodule TdBgWeb.AclEntry do
  @moduledoc false

  alias Poison, as: JSON
  import TdBgWeb.Router.Helpers
  import TdBgWeb.Authentication, only: :functions
  @endpoint TdBgWeb.Endpoint

  def acl_entry_create(token, acl_entry_params) do
    headers = get_header(token)
    body = %{acl_entry: acl_entry_params} |> JSON.encode!
    %HTTPoison.Response{status_code: status_code, body: resp} =
      HTTPoison.post!(acl_entry_url(@endpoint, :create), body, headers, [])
    {:ok, status_code, resp |> JSON.decode!}
  end

  def get_acls(token) do
    headers = get_header(token)
    %HTTPoison.Response{status_code: status_code, body: resp} =
      HTTPoison.get!(acl_entry_url(@endpoint, :index), headers, [])
    {:ok, status_code, resp |> JSON.decode!}
  end

end
