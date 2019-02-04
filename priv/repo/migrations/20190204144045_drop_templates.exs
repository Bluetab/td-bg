defmodule TdBg.Repo.Migrations.DropTemplates do
  use Ecto.Migration

  def change do
    execute("delete from templates")
    drop unique_index(:templates, [:name])
    drop table("templates")
  end
end
