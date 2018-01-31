defmodule TrueBG.Repo.Migrations.CreateBusinessConcepts do
  use Ecto.Migration

  def change do
    create table(:business_concepts) do
      add :type, :string, null: false
      add :name, :string, null: false, size: 255
      add :description, :string, size: 500
      add :content, :json, null: false # json
      #add :content, :map  # jsonb
      add :modifier, references(:users), null: false
      add :last_change, :utc_datetime, null: false
      add :data_domain_id, references(:data_domains), null: false
      add :status, :string, null: false
      add :version, :integer, null: false

      timestamps()
    end
  end
end
