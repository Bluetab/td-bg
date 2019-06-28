defmodule TdBg.Repo.Migrations.AlterBusinessConceptRemoveParentId do
  use Ecto.Migration

  def change do
    alter(table(:business_concepts), do: remove(:parent_id))
  end
end
