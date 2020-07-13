defmodule TdBg.Repo.Migrations.AddUniqueBusinessConceptKey do
  use Ecto.Migration

  def change do
    create(
      unique_index(:business_concepts, [:name, :type], name: :index_business_concept_by_name_type)
    )
  end
end
