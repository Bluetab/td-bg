defmodule TdBg.Repo.Migrations.BusinessConceptDataFields do
  use Ecto.Migration

  def change do
    create table(:business_concept_data_fields) do
      add :business_concept, :string
      add :data_field, :string

      timestamps()
    end

  end
end
