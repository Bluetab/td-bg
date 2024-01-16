defmodule TdBg.BusinessConcepts.BulkUploadEventsTest do
  use TdBg.DataCase

  alias TdBg.BusinessConcepts.BulkUploadEvents

  describe "bulk_upload_events" do
    alias TdBg.BusinessConcepts.BulkUploadEvent

    @invalid_attrs %{
      file_hash: nil,
      filename: nil,
      message: nil,
      response: nil,
      status: nil,
      task_reference: nil,
      user_id: nil
    }

    test "list_bulk_upload_events/0 returns all bulk_upload_events" do
      %{id: id, status: status, file_hash: file_hash} = insert(:bulk_upload_event)

      assert assert [
                      %{
                        id: ^id,
                        status: ^status,
                        file_hash: ^file_hash
                      }
                    ] = BulkUploadEvents.list_bulk_upload_events()
    end

    test "get_bulk_upload_event!/1 returns the bulk_upload_event with given id" do
      %{id: id, status: status, file_hash: file_hash} = insert(:bulk_upload_event)

      assert %{
               id: ^id,
               status: ^status,
               file_hash: ^file_hash
             } = BulkUploadEvents.get_bulk_upload_event!(id)
    end

    test "get_by_user_is/1 returns the bulk_upload_events for specific user" do
      user_id_1 = 1
      user_id_2 = 2

      %{id: id_1, status: status, file_hash: file_hash} =
        insert(:bulk_upload_event, user_id: user_id_1)

      insert(:bulk_upload_event, user_id: user_id_2)

      assert [
               %{
                 id: ^id_1,
                 status: ^status,
                 file_hash: ^file_hash,
                 user_id: ^user_id_1
               }
             ] = BulkUploadEvents.get_by_user_id(user_id_1)
    end

    test "create_bulk_upload_event/1 with valid data creates a bulk_upload_event" do
      valid_attrs = %{
        file_hash: "some file_hash",
        filename: "some filename",
        message: "some message",
        response: %{},
        status: "some status",
        task_reference: "some task_reference",
        user_id: 42
      }

      assert {:ok, %BulkUploadEvent{} = bulk_upload_event} =
               BulkUploadEvents.create_bulk_upload_event(valid_attrs)

      assert bulk_upload_event.file_hash == "some file_hash"
      assert bulk_upload_event.filename == "some filename"
      assert bulk_upload_event.message == "some message"
      assert bulk_upload_event.response == %{}
      assert bulk_upload_event.status == "some status"
      assert bulk_upload_event.task_reference == "some task_reference"
      assert bulk_upload_event.user_id == 42
    end

    test "create_bulk_upload_event/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} =
               BulkUploadEvents.create_bulk_upload_event(@invalid_attrs)
    end

    test "update_bulk_upload_event/2 with valid data updates the bulk_upload_event" do
      bulk_upload_event = insert(:bulk_upload_event)

      update_attrs = %{
        file_hash: "some updated file_hash",
        filename: "some updated filename",
        message: "some updated message",
        response: %{},
        status: "some updated status",
        task_reference: "some updated task_reference",
        user_id: 43
      }

      assert {:ok, %BulkUploadEvent{} = bulk_upload_event} =
               BulkUploadEvents.update_bulk_upload_event(bulk_upload_event, update_attrs)

      assert bulk_upload_event.file_hash == "some updated file_hash"
      assert bulk_upload_event.filename == "some updated filename"
      assert bulk_upload_event.message == "some updated message"
      assert bulk_upload_event.response == %{}
      assert bulk_upload_event.status == "some updated status"
      assert bulk_upload_event.task_reference == "some updated task_reference"
      assert bulk_upload_event.user_id == 43
    end

    test "update_bulk_upload_event/2 with invalid data returns error changeset" do
      %{id: id, status: status, file_hash: file_hash} =
        bulk_upload_event = insert(:bulk_upload_event)

      assert {:error, %Ecto.Changeset{}} =
               BulkUploadEvents.update_bulk_upload_event(bulk_upload_event, @invalid_attrs)

      assert %{
               id: ^id,
               status: ^status,
               file_hash: ^file_hash
             } = BulkUploadEvents.get_bulk_upload_event!(id)
    end

    test "delete_bulk_upload_event/1 deletes the bulk_upload_event" do
      bulk_upload_event = insert(:bulk_upload_event)

      assert {:ok, %BulkUploadEvent{}} =
               BulkUploadEvents.delete_bulk_upload_event(bulk_upload_event)

      assert_raise Ecto.NoResultsError, fn ->
        BulkUploadEvents.get_bulk_upload_event!(bulk_upload_event.id)
      end
    end

    test "change_bulk_upload_event/1 returns a bulk_upload_event changeset" do
      bulk_upload_event = insert(:bulk_upload_event)
      assert %Ecto.Changeset{} = BulkUploadEvents.change_bulk_upload_event(bulk_upload_event)
    end
  end
end
