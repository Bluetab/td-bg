defmodule TdBgWeb.BulkUploadEventControllerTest do
  use TdBgWeb.ConnCase

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    @tag authentication: [role: "admin"]
    test "lists all bulk_upload_events", %{conn: conn, claims: %{user_id: user_id}} do
      %{id: id} = insert(:bulk_upload_event, user_id: user_id)

      conn = get(conn, Routes.bulk_upload_event_path(conn, :index))
      assert [%{"id" => ^id}] = json_response(conn, 200)["data"]
    end
  end
end
