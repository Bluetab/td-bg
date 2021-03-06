defmodule TdBg.Repo.Migrations.CreateDomain do
  use Ecto.Migration

  def change do
    create table(:domains) do
      add(:name, :string)
      add(:type, :string, null: true)
      add(:description, :string)
      add(:parent_id, references(:domains), null: true)
      timestamps(type: :utc_datetime_usec)
    end
  end
end
