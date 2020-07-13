defmodule TdBg.Repo.Migrations.AddParentConcept do
  use Ecto.Migration

  def change do
    alter(table(:business_concepts),
      do: add(:parent_id, references(:business_concepts), null: true)
    )
  end
end
