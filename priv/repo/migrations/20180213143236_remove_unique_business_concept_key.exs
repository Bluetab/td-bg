defmodule TdBg.Repo.Migrations.RemoveUniqueBusinessConceptKey do
  use Ecto.Migration

  def change do
    drop unique_index(:business_concepts, [:name, :type], name: :index_business_concept_by_name_type)
  end
end
