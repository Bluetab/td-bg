defmodule TdBgWeb.AclEntry do
  @moduledoc false

  def acl_entry_create(acl_entry_params) do
    MockPermissionResolver.create_acl_entry(acl_entry_params)
    {:ok, 200, %{}}
  end
end
