defmodule TdBg.Repo.Migrations.CreatePermission do
  use Ecto.Migration

  def change do
    create table(:permissions) do
      add :name, :string

      timestamps(type: :utc_datetime)
    end

    create unique_index(:permissions, [:name])

  end
end
