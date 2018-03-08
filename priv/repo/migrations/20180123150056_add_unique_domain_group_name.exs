defmodule TdBg.Repo.Migrations.AddUniqueDomainGroupName do
  use Ecto.Migration

  def change do
    create unique_index(:domain_groups, [:name])
  end
end
