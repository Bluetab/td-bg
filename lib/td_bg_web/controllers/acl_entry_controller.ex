defmodule TdBGWeb.AclEntryController do
  use TdBGWeb, :controller
  use PhoenixSwagger

  alias TdBG.Permissions
  alias TdBG.Permissions.AclEntry
  alias TdBGWeb.ErrorView
  alias Guardian.Plug, as: GuardianPlug
  alias TdBGWeb.SwaggerDefinitions
  alias TdBG.Utils.CollectionUtils
  import Canada

  action_fallback TdBGWeb.FallbackController

  def swagger_definitions do
    SwaggerDefinitions.acl_entry_swagger_definitions()
  end

  swagger_path :index do
    get "/acl_entries"
    description "List Acl Entries"
    response 200, "OK", Schema.ref(:AclEntriesResponse)
  end

  def index(conn, _params) do
    acl_entries = Permissions.list_acl_entries()
    render(conn, "index.json", acl_entries: acl_entries)
  end

  swagger_path :create do
    post "/acl_entries"
    description "Creates an Acl Entry"
    produces "application/json"
    parameters do
      acl_entry :body, Schema.ref(:AclEntryCreateUpdate), "Acl entry create attrs"
    end
    response 201, "OK", Schema.ref(:AclEntryResponse)
    response 400, "Client Error"
  end

  def create(conn, %{"acl_entry" => acl_entry_params}) do
    acl_entry = %AclEntry{} |> Map.merge(CollectionUtils.to_struct(AclEntry, acl_entry_params))
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

  swagger_path :show do
    get "/acl_entries/{id}"
    description "Show Acl Entry"
    produces "application/json"
    parameters do
      id :path, :integer, "Acl Entry ID", required: true
    end
    response 200, "OK", Schema.ref(:AclEntryResponse)
    response 400, "Client Error"
  end

  def show(conn, %{"id" => id}) do
    acl_entry = Permissions.get_acl_entry!(id)
    render(conn, "show.json", acl_entry: acl_entry)
  end

  swagger_path :update do
    put "/acl_entries/{id}"
    description "Updates Acl entry"
    produces "application/json"
    parameters do
      acl_entry :body, Schema.ref(:AclEntryCreateUpdate), "Acl entry update attrs"
      id :path, :integer, "Acl Entry ID", required: true
    end
    response 200, "OK", Schema.ref(:AclEntryResponse)
    response 400, "Client Error"
  end

  def update(conn, %{"id" => id, "acl_entry" => acl_entry_params}) do
    acl_entry = Permissions.get_acl_entry!(id)

    with {:ok, %AclEntry{} = acl_entry} <- Permissions.update_acl_entry(acl_entry, acl_entry_params) do
      render(conn, "show.json", acl_entry: acl_entry)
    end
  end

  swagger_path :delete do
    delete "/acl_entries/{id}"
    description "Delete Acl Entry"
    produces "application/json"
    parameters do
      id :path, :integer, "Acl entry ID", required: true
    end
    response 204, "OK"
    response 400, "Client Error"
  end

  def delete(conn, %{"id" => id}) do
    acl_entry = Permissions.get_acl_entry!(id)
    with {:ok, %AclEntry{}} <- Permissions.delete_acl_entry(acl_entry) do
      send_resp(conn, :no_content, "")
    end
  end
end