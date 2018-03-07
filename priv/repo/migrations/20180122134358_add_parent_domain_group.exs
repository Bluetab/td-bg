defmodule TdBG.Repo.Migrations.AddParentDomainGroup do
  use Ecto.Migration

  def change do
    alter table(:domain_groups) do
      add :parent_id, references(:domain_groups), null: true
    end
  end
end
