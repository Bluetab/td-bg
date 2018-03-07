defmodule TdBG.Repo.Migrations.DropBusinessConcept do
  use Ecto.Migration

  def change do
    drop unique_index(:business_concepts, [:version, :version_group_id], name: :index_business_concept_by_version_version_group_id)
    drop table("business_concepts")
  end
end
