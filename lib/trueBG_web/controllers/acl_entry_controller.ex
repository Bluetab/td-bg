defmodule TrueBGWeb.AclEntryController do
  use TrueBGWeb, :controller

  alias TrueBG.Permissions
  alias TrueBG.Permissions.AclEntry
  alias TrueBGWeb.ErrorView
  alias Guardian.Plug, as: GuardianPlug
  import Canada

  action_fallback TrueBGWeb.FallbackController

  def index(conn, _params) do
    acl_entries = Permissions.list_acl_entries()
    render(conn, "index.json", acl_entries: acl_entries)
  end

  def to_struct(kind, attrs) do
    struct = struct(kind)
    Enum.reduce Map.to_list(struct), struct, fn {k, _}, acc ->
      case Map.fetch(attrs, Atom.to_string(k)) do
        {:ok, v} -> %{acc | k => v}
        :error -> acc
      end
    end
  end

  def create(conn, %{"acl_entry" => acl_entry_params}) do
    acl_entry = %AclEntry{} |> Map.merge(to_struct(AclEntry, acl_entry_params))
    current_user = GuardianPlug.current_resource(conn)

    if current_user |> can?(create(acl_entry)) do
      with {:ok, %AclEntry{} = acl_entry} <- Permissions.create_acl_entry(acl_entry_params) do
        conn
        |> put_status(:created)
        |> put_resp_header("location", acl_entry_path(conn, :show, acl_entry))
        |> render("show.json", acl_entry: acl_entry)
      else
        _error ->
          conn
          |> put_status(:unprocessable_entity)
          |> render(ErrorView, :"422.json")
      end
    else
      conn
      |> put_status(403)
      |> render(ErrorView, :"403")
    end
  end

  def show(conn, %{"id" => id}) do
    acl_entry = Permissions.get_acl_entry!(id)
    render(conn, "show.json", acl_entry: acl_entry)
  end

  def update(conn, %{"id" => id, "acl_entry" => acl_entry_params}) do
    acl_entry = Permissions.get_acl_entry!(id)

    with {:ok, %AclEntry{} = acl_entry} <- Permissions.update_acl_entry(acl_entry, acl_entry_params) do
      render(conn, "show.json", acl_entry: acl_entry)
    end
  end

  def delete(conn, %{"id" => id}) do
    acl_entry = Permissions.get_acl_entry!(id)
    with {:ok, %AclEntry{}} <- Permissions.delete_acl_entry(acl_entry) do
      send_resp(conn, :no_content, "")
    end
  end
end
