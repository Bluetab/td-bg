defmodule TdBG.Repo.Migrations.CreateDataDomains do
  use Ecto.Migration

  def change do
    create table(:data_domains) do
      add :name, :string
      add :description, :string
      add :domain_group_id, references(:domain_groups, on_delete: :nothing)

      timestamps()
    end

  end
end
