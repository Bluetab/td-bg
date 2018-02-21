defmodule TrueBG.Repo.Migrations.AddUniqueBusinessConceptVersionVersionGroup do
  use Ecto.Migration

  def change do
    create unique_index(:business_concepts, [:version, :version_group_id], name: :index_business_concept_by_version_version_group_id)
  end
end
