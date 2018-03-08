defmodule TdBg.Repo.Migrations.AddLogicalDeletionToDataDomain do
  use Ecto.Migration

  def change do
    alter table(:data_domains) do
      add :deleted_at, :utc_datetime, null: true, default: nil
    end
  end
end
