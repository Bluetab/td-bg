defmodule TdBg.Repo.Migrations.AddBusinessConceptCurrentVersion do
  use Ecto.Migration

  def change do
    alter table(:business_concepts) do
      add :last_version_id, references(:business_concepts), null: true
      add :mod_comments, :string, size: 500, null: true
    end
  end
end
