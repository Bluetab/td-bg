defmodule TdBg.Repo.Migrations.CreateDomainUniqueIndices do
  use Ecto.Migration

  def change do
    create(unique_index(:domains, [:external_id], where: "deleted_at is null"))
    create(unique_index(:domains, [:name], where: "deleted_at is null"))
  end
end
