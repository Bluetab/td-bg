defmodule TrueBG.Repo.Migrations.CreateBusinessConceptVersions do
  use Ecto.Migration

  def change do
    create table(:business_concept_versions) do
      add :business_concept_id, references(:business_concepts), null: false
      add :name, :string, null: false, size: 255
      add :description, :string, size: 500
      add :content, :map
      add :last_change_by, :bigint, null: false
      add :last_change_at, :utc_datetime, null: false
      add :status, :string, null: false
      add :version, :integer, null: false
      add :reject_reason, :string, size: 500, null: true
      add :mod_comments, :string, size: 500, null: true

      timestamps()
    end
  end
end
