defmodule TdBg.Repo.Migrations.ConceptFields do
  use Ecto.Migration

  def change do
    create table(:concept_fields) do
      add :concept, :string
      add :field, :string

      timestamps()
    end
    create unique_index(:concept_fields, [:concept, :field])
  end
end
