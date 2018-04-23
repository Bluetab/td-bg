defmodule TdBg.Repo.Migrations.CreateBusinessConcepts do
  use Ecto.Migration

  def change do
    create table(:business_concepts) do
      add :type, :string, null: false
      add :name, :string, null: false, size: 255
      add :description, :string, size: 500
      add :content, :map
      add :last_change_by, :bigint, null: false
      add :last_change_at, :utc_datetime, null: false
      add :domain_id, references(:domains), null: false
      add :status, :string, null: false
      add :version, :integer, null: false

      timestamps()
    end
  end
end
