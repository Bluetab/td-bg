defmodule TdBg.Repo.Migrations.CreateBusinessConcept do
  use Ecto.Migration

  def change do
    create table(:business_concepts) do
      add :domain_id, references(:domains), null: false
      add :type, :string, null: false
      add :last_change_by, :bigint, null: false
      add :last_change_at, :utc_datetime, null: false
      timestamps(type: :utc_datetime)
    end
  end
end
