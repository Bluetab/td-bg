defmodule TdBgWeb.BulkUploadEventController do
  use TdBgWeb, :controller

  import Canada.Can, only: [can?: 3]

  alias TdBg.BusinessConcepts.BulkUploadEvents
  alias TdBg.BusinessConcepts.BusinessConceptVersion

  action_fallback(TdBgWeb.FallbackController)

  def index(conn, _params) do
    with %{user_id: user_id} = claims <- conn.assigns[:current_resource],
         {:can, true} <- {:can, can?(claims, :upload, BusinessConceptVersion)} do
      render(conn, "index.json", bulk_upload_events: BulkUploadEvents.get_by_user_id(user_id))
    end
  end
end
