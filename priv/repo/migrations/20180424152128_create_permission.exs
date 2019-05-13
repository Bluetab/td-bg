defmodule TdBg.Repo.Migrations.CreatePermission do
  use Ecto.Migration

  def change do
    create table(:permissions) do
      add(:name, :string)

      timestamps(type: :utc_datetime_usec)
    end

    create(unique_index(:permissions, [:name]))
  end
end
