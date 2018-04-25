defmodule TdBg.Repo.Migrations.CreateTemplates do
  use Ecto.Migration

  def change do
    create table(:templates) do
      add :name, :string
      add :content, {:array, :map}

      timestamps()
    end

  end
end
