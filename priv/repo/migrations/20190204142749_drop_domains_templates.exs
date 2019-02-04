defmodule TdBg.Repo.Migrations.DropDomainsTemplates do
  use Ecto.Migration

  def change do
    drop unique_index(:domains_templates, [:domain_id, :template_id])
    drop table("domains_templates")
  end
end
