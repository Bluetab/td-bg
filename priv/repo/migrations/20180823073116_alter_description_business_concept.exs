defmodule TdBg.Repo.Migrations.AlterDescriptionBusinessConcept do
  use Ecto.Migration

  def change do
    alter table(:business_concept_versions) do
      modify(:description, :text)
    end
  end
end
