defmodule TdBg.Repo.Migrations.AddDomainExternalId do
  use Ecto.Migration

  def change do
    alter table(:domains) do
      add :external_id, :string, null: true
    end
  end
end
