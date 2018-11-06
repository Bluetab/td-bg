defmodule TdBg.Repo.Migrations.RemoveTemplatesModel do
  use Ecto.Migration

  def change do
    drop table(:domains_templates)
    drop table(:templates)
  end
end
