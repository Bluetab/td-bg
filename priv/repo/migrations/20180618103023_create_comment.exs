defmodule TdBg.Repo.Migrations.CreateComment do
  use Ecto.Migration

  def change do
    create table(:comments) do
      add :content, :string
      add :resource_id, :integer
      add :resource_type, :string
      add :user, :map
      add :created_at, :utc_datetime

      timestamps()
    end
  end
end
