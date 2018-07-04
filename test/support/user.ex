defmodule TdBgWeb.User do
  @moduledoc false

  @td_auth_api Application.get_env(:td_bg, :auth_service)[:api_service]

  def role_list(_token) do
    @td_auth_api.index_roles()
  end

  def get_role_by_name(role_name) do
    @td_auth_api.find_or_create_role(role_name)
  end

  def is_admin_bool(is_admin) do
    case is_admin do
      "yes" -> true
      "no" -> false
      _ -> is_admin
    end
  end

  def get_group_by_name(group_name) do
    @td_auth_api.get_group_by_name(group_name)
  end
end
