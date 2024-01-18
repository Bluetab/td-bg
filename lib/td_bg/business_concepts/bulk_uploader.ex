defmodule TdBg.BusinessConcepts.BulkUploader do
  @moduledoc """
  Business concepts bulk upload GenServer
  """

  use GenServer

  require Logger

  alias TdBg.BusinessConcept.Upload
  alias TdBg.BusinessConcepts.BulkUploadEvent
  alias TdBg.BusinessConcepts.BulkUploadEvents

  @shutdown_timeout 2000

  @doc """
  Starts the `GenServer`
  """
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def bulk_upload(file_hash, business_concepts_upload, claims, auto_publish, lang) do
    GenServer.call(
      __MODULE__,
      {:bulk_upload, file_hash, business_concepts_upload, claims, auto_publish, lang},
      60_000
    )
  end

  ## GenServer callbacks
  @impl true
  def init(opts) do
    name = String.replace_prefix("#{__MODULE__}", "Elixir.", "")
    Logger.info("Running #{name}")
    {:ok, %{tasks: %{}, notify: Keyword.get(opts, :notify)}}
  end

  @impl true
  def handle_call(
        {:bulk_upload, file_hash, business_concepts_upload, claims, auto_publish, lang},
        _from,
        state
      ) do
    %{reply: upload_state, state: new_state} =
      file_hash
      |> pending_upload()
      |> launch_task(file_hash, state, business_concepts_upload, claims, auto_publish, lang)

    {:reply, upload_state, new_state}
  end

  # If the task succeeds...
  @impl true
  def handle_info({ref, {:error, error}}, state) do
    # The task succeed so we can cancel the monitoring and discard the DOWN message
    Process.demonitor(ref, [:flush])

    {%{task_timer: task_timer, file_hash: file_hash} = task_info, state} =
      pop_in(state.tasks[ref])

    Process.cancel_timer(task_timer)
    create_event(task_info, :DOWN, error)
    clean_tmp_file(file_hash)
    {:noreply, state}
  end

  @impl true
  def handle_info({ref, summary}, state) when is_reference(ref) do
    # The task succeed so we can cancel the monitoring and discard the DOWN message
    Process.demonitor(ref, [:flush])

    {%{task_timer: task_timer, file_hash: file_hash} = task_info, state} =
      pop_in(state.tasks[ref])

    Process.cancel_timer(task_timer)
    create_event(summary, task_info)
    clean_tmp_file(file_hash)
    {:noreply, state}
  end

  # If the task fails...
  @impl true
  def handle_info({:DOWN, ref, _, _pid, _reason}, state) when is_reference(ref) do
    {%{task_timer: task_timer, file_hash: file_hash} = task_info, state} =
      pop_in(state.tasks[ref])

    Process.cancel_timer(task_timer)
    create_event(task_info, :DOWN, %{error: :unexpected_error})
    clean_tmp_file(file_hash)
    {:noreply, state}
  end

  @impl true
  def handle_info({:timeout, %{ref: ref} = task}, state) when is_reference(ref) do
    {%{file_hash: file_hash} = task_info, state} = pop_in(state.tasks[ref])

    Logger.warn(
      "Task timeout, reference: #{inspect(ref)}}, trying to shut it down in #{@shutdown_timeout}..."
    )

    case Task.shutdown(task, @shutdown_timeout) do
      {:ok, reply} ->
        # Reply received while shutting down
        create_event(task_info, :timeout, reply)

      {:exit, reason} ->
        # Task died
        create_event(task_info, :timeout, reason)

      nil ->
        create_event(task_info, :timeout, "shutdown")
    end

    clean_tmp_file(file_hash)
    {:noreply, state}
  end

  defp launch_task(
         :not_pending,
         file_hash,
         state,
         %{filename: filename} = business_concepts_upload,
         %{user_id: user_id} = claims,
         auto_publish,
         lang
       ) do
    file = create_tmp_file(business_concepts_upload, file_hash)

    task =
      Task.Supervisor.async_nolink(
        TdBg.TaskSupervisor,
        fn ->
          with %{created: _, updated: _, error: _} = result <-
                 Upload.bulk_upload(file, claims,
                   auto_publish: auto_publish,
                   lang: lang
                 ) do
            result
          end
        end
      )

    task_timer = Process.send_after(self(), {:timeout, task}, timeout())

    BulkUploadEvents.create_bulk_upload_event(%{
      user_id: user_id,
      status: "STARTED",
      file_hash: file_hash,
      task_reference: ref_to_string(task.ref),
      filename: filename
    })

    %{
      reply: {:started, file_hash, ref_to_string(task.ref)},
      state:
        put_in(
          state.tasks[task.ref],
          %{
            task: task,
            task_timer: task_timer,
            file_hash: file_hash,
            filename: filename,
            user_id: user_id,
            auto_publish: auto_publish
          }
        )
    }
  end

  defp launch_task(
         {:running, _event_pending} = update_state,
         _file_hash,
         state,
         _business_concepts_upload,
         _claims,
         _auto_publish,
         _lang
       ) do
    %{reply: update_state, state: state}
  end

  defp pending_upload(file_hash) do
    case BulkUploadEvents.last_event_by_hash(file_hash) do
      %BulkUploadEvent{status: "STARTED", inserted_at: inserted_at} = event ->
        if DateTime.compare(
             DateTime.add(inserted_at, timeout(), :second),
             DateTime.utc_now()
           ) in [:lt, :eq] do
          :not_pending
        else
          {:running, event}
        end

      _ ->
        :not_pending
    end
  end

  def create_event(summary, task_info) do
    %{file_hash: file_hash, filename: filename, user_id: user_id, task: %{ref: ref}} = task_info

    BulkUploadEvents.create_bulk_upload_event(%{
      response: summary,
      user_id: user_id,
      file_hash: file_hash,
      filename: filename,
      status: "COMPLETED",
      task_reference: ref_to_string(ref)
    })
  end

  def create_event(task_info, fail_type, message) do
    %{file_hash: file_hash, filename: filename, user_id: user_id, task: %{ref: ref}} = task_info

    BulkUploadEvents.create_bulk_upload_event(%{
      user_id: user_id,
      file_hash: file_hash,
      filename: filename,
      status: fail_type_to_str(fail_type),
      task_reference: ref_to_string(ref),
      message: "#{fail_type}, #{inspect(message)}"
    })
  end

  defp timeout do
    :td_bg
    |> Application.get_env(TdBg.BusinessConcepts.BulkUploader)
    |> Keyword.get(:timeout, 600)
    |> Kernel.*(1000)
  end

  defp uploads_tmp_folder do
    :td_bg
    |> Application.get_env(TdBg.BusinessConcepts.BulkUploader)
    |> Keyword.get(:uploads_tmp_folder)
  end

  defp create_tmp_file(%{path: path} = business_concepts_upload, file_hash) do
    new_path = Path.join(uploads_tmp_folder(), file_hash)
    File.rename!(path, new_path)
    Map.put(business_concepts_upload, :path, new_path)
  end

  defp clean_tmp_file(file_hash) do
    uploads_tmp_folder()
    |> Path.join(file_hash)
    |> File.rm()
  end

  defp ref_to_string(ref) when is_reference(ref) do
    string_ref =
      ref
      |> :erlang.ref_to_list()
      |> List.to_string()

    Regex.run(~r/<(.*)>/, string_ref)
    |> Enum.at(1)
  end

  defp fail_type_to_str(fail_type) do
    case fail_type do
      :DOWN -> "FAILED"
      :timeout -> "TIMED_OUT"
    end
  end
end
