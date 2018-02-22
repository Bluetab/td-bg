defmodule TrueBG.Repo.Migrations.AddUniqueDataDomainByDomainGroup2 do
  use Ecto.Migration

  def change do
    drop index(:data_domains, [:name, :domain_group_id], name: :index_data_domain_name_on_domain_group)
    create unique_index(:data_domains, [:name, :domain_group_id], where: "deleted_at is null")
  end
end
