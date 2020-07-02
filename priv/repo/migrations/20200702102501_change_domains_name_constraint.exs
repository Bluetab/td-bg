defmodule TdBg.Repo.Migrations.ChangeDomainsNameConstraint do
  use Ecto.Migration

  def up do
    drop unique_index(:domains, [:name], name: :domains_name_index)

    create(
      unique_index(:domains, [:domain_group_id, :name],
        where: "domain_group_id is not null and deleted_at is null"
      )
    )

    create(
      unique_index(:domains, [:name], where: "domain_group_id is null and deleted_at is null")
    )
  end

  def down do
    drop unique_index(:domains, [:name])
    drop unique_index(:domains, [:domain_group_id, :name])
    
    create(unique_index(:domains, [:name], where: "deleted_at is null"))
  end
end
