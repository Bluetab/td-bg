defmodule TdBg.Repo.Migrations.DropBusinessConceptAliases do
  use Ecto.Migration

  def change do
    drop(index(:business_concept_aliases, [:business_concept_id]))
    drop(table("business_concept_aliases"))
  end
end
