defmodule TdBg.Repo.Migrations.CreateBusinessConceptAliases do
  use Ecto.Migration

  def change do
    create table(:business_concept_aliases) do
      add(:name, :string)
      add(:business_concept_id, references(:business_concepts, on_delete: :nothing))

      timestamps(type: :utc_datetime_usec)
    end

    create(index(:business_concept_aliases, [:business_concept_id]))
  end
end
