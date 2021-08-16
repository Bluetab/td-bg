defmodule TdBg.Repo.Migrations.AddSharedConcepts do
  use Ecto.Migration

  def up do
    create table(:shared_concepts) do
      add(:business_concept_id, references(:business_concepts), on_delete: :delete_all)
      add(:domain_id, references(:domains), on_delete: :delete_all)

      timestamps(type: :utc_datetime_usec, updated_at: false)
    end

    create(unique_index(:shared_concepts, [:business_concept_id, :domain_id]))
  end

  def down do
    drop(table(:shared_concepts))
  end
end
