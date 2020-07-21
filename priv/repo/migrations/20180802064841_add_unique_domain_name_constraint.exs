defmodule TdBg.Repo.Migrations.AddUniqueDomainNameConstraint do
  use Ecto.Migration

  def change do
    create(unique_index(:domains, [:name], name: :index_domain_by_name))
  end
end
