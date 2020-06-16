defmodule TdBg.Repo.Migrations.AlterCommentsTimestamps do
  use Ecto.Migration

  def change do
    alter table(:comments) do
      remove(:created_at, :utc_datetime_usec)
      remove(:updated_at, :utc_datetime_usec)
    end
  end
end
