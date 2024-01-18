defmodule TdBg.Repo.Migrations.CreateBulkUploadEvents do
  use Ecto.Migration

  def change do
    create table(:bulk_upload_events) do
      add(:user_id, :bigint)
      add(:response, :map)
      add(:file_hash, :string)
      add(:task_reference, :string)
      add(:status, :string)
      add(:node, :string)
      add(:message, :string, size: 10_000)
      add(:filename, :string)

      timestamps(updated_at: false, type: :utc_datetime_usec)
    end
  end
end
