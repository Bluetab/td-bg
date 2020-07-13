defmodule TdBg.Repo.Migrations.BusinessConceptRelatedTo do
  use Ecto.Migration

  def change do
    alter table(:business_concept_versions) do
      add(:related_to, {:array, :integer}, null: false)
    end
  end
end
