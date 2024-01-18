defmodule TdBg.Jobs.UploadTmpFilesCleaner do
  @moduledoc """
  Upload temp files cleaner
  """

  alias TdBg.BusinessConcepts.BulkUploadEvents
  require Logger

  def run do
    case BulkUploadEvents.event_started_and_not_finished() do
      [] ->
        Logger.info("There are no orphaned temporary files")

      [_ | _] = orphaned_events ->
        Enum.each(orphaned_events, fn event ->
          clean_tmp_file(event.file_hash)

          BulkUploadEvents.create_bulk_upload_event(%{
            user_id: event.user_id,
            file_hash: event.file_hash,
            filename: event.filename,
            status: "FAILED",
            task_reference: event.task_reference,
            message: "DOWN, Process stopped unexpectedly"
          })

          Logger.info("Removed bulk upload temp file #{event.file_hash}")
        end)
    end
  end

  defp uploads_tmp_folder do
    :td_bg
    |> Application.get_env(TdBg.BusinessConcepts.BulkUploader)
    |> Keyword.get(:uploads_tmp_folder)
  end

  defp clean_tmp_file(file_hash) do
    uploads_tmp_folder()
    |> Path.join(file_hash)
    |> File.rm()
  end
end
