defmodule TrueBG.Repo.Migrations.AddUniqueDataDomainByDomainGroup do
  use Ecto.Migration

  def change do
    create unique_index(:data_domains, [:name, :domain_group_id], name: :index_data_domain_name_on_domain_group)
  end
end
