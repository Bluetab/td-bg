defmodule TdBg.Repo.Migrations.BusinessConceptDataFields do
  use Ecto.Migration

  def change do
    create table(:business_concept_data_fields) do
      add :business_concept, :string
      add :data_field, :string

      timestamps()
    end
    create unique_index(:business_concept_data_fields, [:business_concept, :data_field])
  end
end
