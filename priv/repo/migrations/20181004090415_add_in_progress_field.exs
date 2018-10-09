defmodule TdBg.Repo.Migrations.AddInProgressField do
  use Ecto.Migration

  def up do
    alter table(:business_concept_versions) do
      add :in_progress, :boolean, default: false, null: true
    end

    flush()

    execute("update business_concept_versions set in_progress = false")

    alter table(:business_concept_versions) do
      modify :in_progress, :boolean, default: false, null: false
    end
  end

  def down do
    alter table(:business_concept_versions) do
      remove :in_progress
    end
  end
end
