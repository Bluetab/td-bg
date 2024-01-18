defmodule TdBgWeb.BulkUploadEventView do
  use TdBgWeb, :view
  alias TdBgWeb.BulkUploadEventView

  def render("index.json", %{bulk_upload_events: bulk_upload_events}) do
    %{data: render_many(bulk_upload_events, BulkUploadEventView, "bulk_upload_event.json")}
  end

  def render("show.json", %{bulk_upload_event: bulk_upload_event}) do
    %{data: render_one(bulk_upload_event, BulkUploadEventView, "bulk_upload_event.json")}
  end

  def render("bulk_upload_event.json", %{bulk_upload_event: bulk_upload_event}) do
    %{
      id: bulk_upload_event.id,
      user_id: bulk_upload_event.user_id,
      response: bulk_upload_event.response,
      file_hash: bulk_upload_event.file_hash,
      task_reference: bulk_upload_event.task_reference,
      status: bulk_upload_event.status,
      node: bulk_upload_event.node,
      message: bulk_upload_event.message,
      filename: bulk_upload_event.filename,
      inserted_at: bulk_upload_event.inserted_at
    }
  end
end
