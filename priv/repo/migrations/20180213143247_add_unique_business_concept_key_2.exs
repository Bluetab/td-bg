defmodule TrueBG.Repo.Migrations.AddUniqueBusinessConceptKey2 do
  use Ecto.Migration

  def change do
    create unique_index(:business_concepts, [:version, :name, :type], name: :index_business_concept_by_version_name_type)
  end
end
