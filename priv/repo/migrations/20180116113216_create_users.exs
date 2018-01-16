defmodule TrueBG.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :user_name, :string
      add :password_hash, :string

      timestamps()
    end

  end
end
