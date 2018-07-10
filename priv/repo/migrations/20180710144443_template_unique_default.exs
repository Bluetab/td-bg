defmodule TdBg.Repo.Migrations.TemplateUniqueDefault do
  use Ecto.Migration

  def change do
    create unique_index(:templates, [:is_default], where: "is_default is true")
  end
end
