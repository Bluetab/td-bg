defmodule TrueBGWeb.RoleController do
  use TrueBGWeb, :controller

  alias TrueBG.Permissions
  alias TrueBG.Permissions.Role

  action_fallback TrueBGWeb.FallbackController

  def index(conn, _params) do
    roles = Permissions.list_roles()
    render(conn, "index.json", roles: roles)
  end

  def create(conn, %{"role" => role_params}) do
    with {:ok, %Role{} = role} <- Permissions.create_role(role_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", role_path(conn, :show, role))
      |> render("show.json", role: role)
    end
  end

  def show(conn, %{"id" => id}) do
    role = Permissions.get_role!(id)
    render(conn, "show.json", role: role)
  end

  def update(conn, %{"id" => id, "role" => role_params}) do
    role = Permissions.get_role!(id)

    with {:ok, %Role{} = role} <- Permissions.update_role(role, role_params) do
      render(conn, "show.json", role: role)
    end
  end

  def delete(conn, %{"id" => id}) do
    role = Permissions.get_role!(id)
    with {:ok, %Role{}} <- Permissions.delete_role(role) do
      send_resp(conn, :no_content, "")
    end
  end

  def user_domain_group_role(conn, %{"user_id" => user_id, "domain_group_id" => domain_group_id}) do
    role = Permissions.get_role_in_resource(%{user_id: user_id, domain_group_id: domain_group_id})
    render(conn, "show.json", role: role)
  end

  def user_data_domain_role(conn, %{"user_id" => user_id, "data_domain_id" => data_domain_id}) do
    role = Permissions.get_role_in_resource(%{user_id: user_id, data_domain_id: data_domain_id})
    render(conn, "show.json", role: role)
  end
end
