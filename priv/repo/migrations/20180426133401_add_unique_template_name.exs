defmodule TdBg.Repo.Migrations.AddUniqueTemplateName do
  use Ecto.Migration

  def change do
      create unique_index(:templates, [:name])
  end
end
