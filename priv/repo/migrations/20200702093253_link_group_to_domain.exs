defmodule TdBg.Repo.Migrations.LinkGroupToDomain do
  use Ecto.Migration

  def up do
    alter table(:domains) do
      add(:domain_group_id, references(:domain_groups), null: true)
    end
  end

  def down do
    alter table(:domains) do
      remove(:domain_group_id, references(:domain_groups), null: true)
    end
  end
end
