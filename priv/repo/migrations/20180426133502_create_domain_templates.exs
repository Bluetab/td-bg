defmodule TdBg.Repo.Migrations.CreateDomainTemplates do
  use Ecto.Migration

  def change do
    create table(:domains_templates) do
      add :domain_id, references(:domains)
      add :template_id, references(:templates)

    end
    create unique_index(:domains_templates, [:domain_id, :template_id])
  end
end
