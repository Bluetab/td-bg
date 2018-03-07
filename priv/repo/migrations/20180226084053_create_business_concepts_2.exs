defmodule TdBG.Repo.Migrations.CreateBusinessConcept do
  use Ecto.Migration

  def change do
    create table(:business_concepts) do
      add :data_domain_id, references(:data_domains), null: false
      add :type, :string, null: false
      add :last_change_by, :bigint, null: false
      add :last_change_at, :utc_datetime, null: false
      timestamps()
    end
  end
end
