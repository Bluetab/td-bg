defmodule TdBg.Repo.Migrations.RemoveBusinessConceptVersionRelatedTo do
  use Ecto.Migration

  def change do
    alter table(:business_concept_versions) do
      remove(:related_to, {:array, :integer}, null: false, default: [])
    end
  end
end
