defmodule TrueBG.Repo.Migrations.CreateDomainGroups do
  use Ecto.Migration

  def change do
    create table(:domain_groups) do
      add :name, :string
      add :description, :string

      timestamps()
    end

  end
end
