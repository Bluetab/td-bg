defmodule TdBG.Repo.Migrations.AddUniqueDomainGroupName2 do
  use Ecto.Migration

  def change do
    drop unique_index(:domain_groups, [:name])
    create unique_index(:domain_groups, [:name], where: "deleted_at is null")
  end
end
