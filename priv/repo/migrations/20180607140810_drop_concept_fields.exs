defmodule TdBg.Repo.Migrations.ConceptFieldsJsonColumn do
  use Ecto.Migration

  def change do
    drop unique_index(:concept_fields, [:concept, :field])
    drop table("concept_fields") 
  end

end
