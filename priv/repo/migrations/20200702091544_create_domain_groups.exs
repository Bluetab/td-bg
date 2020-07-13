defmodule TdBg.Repo.Migrations.CreateDomainGroups do
  use Ecto.Migration

  def up do
    create table(:domain_groups) do
      add(:name, :string)

      timestamps()
    end

    create(unique_index(:domain_groups, [:name], name: :index_domain_group_name))
  end

  def down do
    drop(table(:domain_groups))
  end
end
