defmodule TrueBG.Repo.Migrations.AddLogicalDeletionToDomainGroup do
  use Ecto.Migration

  def change do
    alter table(:domain_groups) do
      add :deleted_at, :utc_datetime, null: true, default: nil
    end
  end
end
