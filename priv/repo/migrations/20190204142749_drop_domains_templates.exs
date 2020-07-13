defmodule TdBg.Repo.Migrations.DropDomainsTemplates do
  use Ecto.Migration

  def change do
    execute("delete from domains_templates")
    drop(unique_index(:domains_templates, [:domain_id, :template_id]))
    drop(table("domains_templates"))
  end
end
