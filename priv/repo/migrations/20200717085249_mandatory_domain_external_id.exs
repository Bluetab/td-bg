defmodule TdBg.Repo.Migrations.MandatoryDomainExternalId do
  use Ecto.Migration

  def up do
    alter table(:domains) do
      modify :external_id, :string, null: false
    end
  end

  def down do
    alter table(:domains) do
      modify :external_id, :string, null: true
    end
  end
end
